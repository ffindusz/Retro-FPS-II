"""Read-only Warden geometry assessment and deterministic local rig helpers."""

from collections import defaultdict
import hashlib
import json
import math
from pathlib import Path
import struct


SOURCE_SHA256 = "969cef958b48e06ce33e40d8efef62797a6cba104a045e4253ac16175135e2d4"

# Fitted to the existing resting pose, in normalized Blender coordinates.
BONES = {
    "Root": ((0, 0, 0), (0, 0, 0.2), None),
    "Pelvis": ((0, -0.01, 0.9), (0, 0, 1.03), "Root"),
    "Spine": ((0, 0, 1.03), (0, 0, 1.27), "Pelvis"),
    "Chest": ((0, 0, 1.27), (0, 0, 1.46), "Spine"),
    "Neck": ((0, 0, 1.46), (0, 0, 1.58), "Chest"),
    "Head": ((0, 0, 1.58), (0, 0, 1.81), "Neck"),
}
for side, sign in (("R", 1), ("L", -1)):
    BONES.update({
        f"Shoulder.{side}": ((0, 0, 1.43), (sign * 0.22, -0.01, 1.42), "Chest"),
        f"UpperArm.{side}": ((sign * 0.22, -0.01, 1.42), (sign * 0.29, -0.035, 1.115), f"Shoulder.{side}"),
        f"Forearm.{side}": ((sign * 0.29, -0.035, 1.115), (sign * 0.278, -0.085, 0.84), f"UpperArm.{side}"),
        f"Hand.{side}": ((sign * 0.278, -0.085, 0.84), (sign * 0.278, -0.085, 0.75), f"Forearm.{side}"),
        f"Thigh.{side}": ((sign * 0.12, -0.025, 0.9), (sign * 0.12, 0.015, 0.49), "Pelvis"),
        f"Shin.{side}": ((sign * 0.12, 0.015, 0.49), (sign * 0.12, -0.02, 0.13), f"Thigh.{side}"),
        f"Foot.{side}": ((sign * 0.12, -0.02, 0.13), (sign * 0.12, 0.16, 0.06), f"Shin.{side}"),
    })
BONES["Weapon.R"] = ((0.278, -0.085, 0.8), (0.33, -0.035, 0.03), "Hand.R")
# The carrying upper arm rests behind the torso, unlike the forward left arm.
BONES["Shoulder.R"] = ((0, 0, 1.43), (0.19, -0.145, 1.4), "Chest")
BONES["UpperArm.R"] = ((0.19, -0.145, 1.4), (0.245, -0.17, 1.12), "Shoulder.R")
BONES["Forearm.R"] = ((0.245, -0.17, 1.12), (0.278, -0.085, 0.84), "UpperArm.R")


def read_glb(path: Path):
    data = path.read_bytes()
    magic, version, length = struct.unpack_from("<4sII", data)
    if magic != b"glTF" or version != 2 or length != len(data):
        raise ValueError("Expected a complete glTF 2.0 binary")
    offset, document, binary = 12, None, None
    while offset < len(data):
        size, kind = struct.unpack_from("<II", data, offset)
        content = data[offset + 8:offset + 8 + size]
        if kind == 0x4E4F534A:
            document = json.loads(content)
        elif kind == 0x004E4942:
            binary = content
        offset += 8 + size
    if document is None or binary is None:
        raise ValueError("Missing JSON/binary GLB chunks")
    return document, binary


def accessor_values(document, binary, index):
    accessor = document["accessors"][index]
    view = document["bufferViews"][accessor["bufferView"]]
    formats = {5121: "B", 5123: "H", 5125: "I", 5126: "f"}
    counts = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}
    fmt = "<" + formats[accessor["componentType"]] * counts[accessor["type"]]
    size = struct.calcsize(fmt)
    stride = view.get("byteStride", size)
    offset = view.get("byteOffset", 0) + accessor.get("byteOffset", 0)
    return [struct.unpack_from(fmt, binary, offset + n * stride) for n in range(accessor["count"])]


def source_mesh(path: Path):
    if hashlib.sha256(path.read_bytes()).hexdigest() != SOURCE_SHA256:
        raise ValueError("Original Warden checksum mismatch; not modifying or rigging an unknown input")
    document, binary = read_glb(path)
    primitive = document["meshes"][0]["primitives"][0]
    source = accessor_values(document, binary, primitive["attributes"]["POSITION"])
    # Exact existing Godot normalization, expressed in Blender Z-up / +Y-forward meters.
    points = [(-x * 1.9, z * 1.9, y * 1.9 + 0.90315) for x, y, z in source]
    indices = [value[0] for value in accessor_values(document, binary, primitive["indices"])]
    faces = [tuple(indices[n:n + 3]) for n in range(0, len(indices), 3)]
    return points, faces


def components(points, faces):
    parents = list(range(len(points)))

    def find(index):
        while parents[index] != index:
            parents[index] = parents[parents[index]]
            index = parents[index]
        return index

    def union(left, right):
        parents[find(left)] = find(right)

    positions = {}
    for index, point in enumerate(points):
        key = tuple(round(value, 5) for value in point)
        if key in positions:
            union(index, positions[key])
        positions[key] = index
    for a, b, c in faces:
        union(a, b)
        union(b, c)
    grouped = defaultdict(list)
    for index in range(len(points)):
        grouped[find(index)].append(index)
    return sorted(grouped.values(), key=lambda group: (-len(group), min(group)))


def bounds(points):
    lower = [min(point[axis] for point in points) for axis in range(3)]
    upper = [max(point[axis] for point in points) for axis in range(3)]
    return {"min": lower, "max": upper, "size": [b - a for a, b in zip(lower, upper)]}


def assess(path: Path):
    points, faces = source_mesh(path)
    groups = components(points, faces)
    report = {
        "source_sha256": SOURCE_SHA256,
        "coordinate_system": "normalized meters, Blender Z-up and +Y-forward",
        "vertices": len(points), "triangles": len(faces), "bounds": bounds(points),
        "welded_position_component_count": len(groups),
        "components": [{"id": n, "vertices": len(group), "bounds": bounds([points[i] for i in group])} for n, group in enumerate(groups)],
        "note": "Connectivity welding is analysis only; source geometry/UVs are not modified.",
    }
    return report


def segment_distance(point, head, tail):
    direction = tuple(b - a for a, b in zip(head, tail))
    square = sum(value * value for value in direction)
    t = max(0.0, min(1.0, sum((p - a) * d for p, a, d in zip(point, head, direction)) / square))
    return math.sqrt(sum((p - (a + t * d)) ** 2 for p, a, d in zip(point, head, direction)))


def identify_regions(points, groups):
    weapon, hand = set(), set()
    for group in groups:
        box = bounds([points[index] for index in group])
        if box["min"][0] > 0.2 and box["max"][2] < 0.8 and box["size"][2] > 0.6:
            weapon.update(group)
        elif box["min"][0] > 0.2 and box["min"][2] > 0.69 and box["max"][2] < 0.9:
            hand.update(group)
    if len(weapon) < 100 or len(hand) < 100:
        raise ValueError("Expected disconnected blade/hand regions not found; manual assessment required")
    return weapon, hand


def vertex_weights(point, region="body"):
    if region == "weapon":
        return {"Weapon.R": 1.0}
    if region == "hand":
        return {"Hand.R": 1.0}
    x, y, z = point
    side = "R" if x >= 0 else "L"
    if z >= 1.59:
        return {"Head": 1.0}
    # The rear coat/cape belongs to the torso, not either nearby arm or thigh.
    cape = y < (-0.245 if abs(x) > 0.18 else -0.15) and z > 0.27 and z < 1.48
    arm_edge = 0.18 if side == "R" and z > 1.28 else 0.21 if side == "R" else 0.225
    arm_bottom = 0.68 if side == "R" and x > 0.225 and -0.18 < y < 0.05 else 0.79
    if not cape and abs(x) > arm_edge and arm_bottom < z < 1.49:
        names = [f"UpperArm.{side}", f"Forearm.{side}", f"Hand.{side}"]
        if z > 1.31:
            names += [f"Shoulder.{side}", "Chest"]
    elif not cape and z < 0.78 and abs(x) > 0.035:
        names = [f"Thigh.{side}", f"Shin.{side}", f"Foot.{side}"]
        if z > 0.65:
            names += ["Pelvis"]
    else:
        names = ["Pelvis", "Spine", "Chest", "Neck", "Head"]
    distances = sorted((segment_distance(point, BONES[name][0], BONES[name][1]), name) for name in names)
    chosen = distances[:2]
    scores = {name: 1.0 / max(distance, 0.025) ** 4 for distance, name in chosen}
    total = sum(scores.values())
    return {name: value / total for name, value in scores.items()}


def mesh_weights(points, faces, iterations=6):
    """Smooth body weights across welded-position topology; never weld geometry.

    This avoids hard spatial thresholds stretching tiny wrist/shoulder triangles.
    Separate hand and blade islands stay rigid throughout smoothing.
    """
    groups = components(points, faces)
    weapon, hand = identify_regions(points, groups)
    keys, representatives, members = {}, [], []
    for index, point in enumerate(points):
        key = tuple(round(value, 5) for value in point)
        if key not in keys:
            keys[key] = len(members)
            members.append([])
        representative = keys[key]
        representatives.append(representative)
        members[representative].append(index)
    adjacent = [set() for group in members]
    for face in faces:
        for a, b in ((face[0], face[1]), (face[1], face[2]), (face[2], face[0])):
            a, b = representatives[a], representatives[b]
            if a != b:
                adjacent[a].add(b)
                adjacent[b].add(a)
    current, fixed = [], set()
    for representative, group in enumerate(members):
        index = group[0]
        region = "weapon" if index in weapon else "hand" if index in hand else "body"
        current.append(vertex_weights(points[index], region))
        if region != "body":
            fixed.add(representative)
    for step in range(iterations):
        updated = []
        for index, neighbors in enumerate(adjacent):
            if index in fixed or not neighbors:
                updated.append(current[index])
                continue
            scores = defaultdict(float)
            for name, value in current[index].items():
                scores[name] += value * 0.5
            # Strongly couple very short edges, which otherwise become visible
            # slivers at UV/normal seams around the wrist and elbow.
            proximity = {neighbor: 1.0 / max(math.dist(points[members[index][0]], points[members[neighbor][0]]), 0.001) ** 2 for neighbor in sorted(neighbors)}
            proximity_total = sum(proximity.values())
            for neighbor, influence in proximity.items():
                for name, value in current[neighbor].items():
                    scores[name] += value * 0.5 * influence / proximity_total
            largest = sorted(scores.items(), key=lambda item: (-item[1], item[0]))[:4]
            total = sum(value for name, value in largest)
            updated.append({name: value / total for name, value in largest if value > 0})
        current = updated
    return [current[representative] for representative in representatives], weapon, hand


def guard_generated_outputs(glb: Path, blend: Path, provenance: Path, replace_generated: bool):
    if not glb.exists() and not blend.exists():
        return
    if not replace_generated or not provenance.exists():
        raise FileExistsError("Existing derivative/authoring output left untouched; use --replace-generated only for unchanged generated outputs")
    previous = json.loads(provenance.read_text(encoding="utf-8"))
    for path, field in ((glb, "glb_sha256"), (blend, "blend_sha256")):
        # Editable .blend is generated/ignored and absent on a fresh checkout.
        if path.exists() and hashlib.sha256(path.read_bytes()).hexdigest() != previous[field]:
            raise ValueError(f"Generated output was modified; preserving user work: {path}")


if __name__ == "__main__":
    root = Path(__file__).resolve().parents[1]
    print(json.dumps(assess(root / "assets/models/enemy-warden/model.glb"), indent=2))
