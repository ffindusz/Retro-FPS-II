"""Offline structural/weapon-weight observations, not an animation-quality score."""

from collections import Counter
import json
from pathlib import Path

from warden_rig_geometry import accessor_values, components, identify_regions, read_glb, source_mesh

ROOT = Path(__file__).resolve().parents[1]


def blade_weight_report(path, source_blade_uvs):
    document, binary = read_glb(path)
    primitive = document["meshes"][0]["primitives"][0]
    attributes = primitive["attributes"]
    uvs = accessor_values(document, binary, attributes["TEXCOORD_0"])
    joints = accessor_values(document, binary, attributes["JOINTS_0"])
    weights = accessor_values(document, binary, attributes["WEIGHTS_0"])
    kind = document["accessors"][attributes["WEIGHTS_0"]]["componentType"]
    divisor = {5121: 255.0, 5123: 65535.0}.get(kind, 1.0)
    names = [document["nodes"][node]["name"] for node in document["skins"][0]["joints"]]
    selected = [index for index, uv in enumerate(uvs) if tuple(round(v, 5) for v in uv) in source_blade_uvs]
    counts = Counter()
    rigid_bones = []
    leg_or_hip = 0
    for index in selected:
        active = [(names[joint], weight / divisor) for joint, weight in zip(joints[index], weights[index]) if weight / divisor > 0.001]
        counts.update(name for name, weight in active)
        if len(active) == 1 and abs(active[0][1] - 1.0) < 0.001:
            rigid_bones.append(active[0][0])
        if any(any(part in name.lower() for part in ("leg", "foot", "toe", "hips", "pelvis")) for name, weight in active):
            leg_or_hip += 1
    return {
        "uv_matched_blade_vertices": len(selected),
        "individually_rigid_vertices": len(rigid_bones),
        "single_shared_rigid_bone": rigid_bones[0] if len(rigid_bones) == len(selected) and len(set(rigid_bones)) == 1 else None,
        "bone_influence_vertex_counts": dict(sorted(counts.items())),
        "leg_or_hip_weighted_blade_vertices": leg_or_hip,
    }


def analyze():
    source = ROOT / "assets/models/enemy-warden/model.glb"
    document, binary = read_glb(source)
    points, faces = source_mesh(source)
    blade, hand = identify_regions(points, components(points, faces))
    uv_accessor = document["meshes"][0]["primitives"][0]["attributes"]["TEXCOORD_0"]
    uvs = accessor_values(document, binary, uv_accessor)
    blade_uvs = {tuple(round(v, 5) for v in uvs[index]) for index in blade}
    body_uvs = {tuple(round(v, 5) for v in uv) for index, uv in enumerate(uvs) if index not in blade}
    if blade_uvs & body_uvs:
        raise ValueError("Ambiguous blade/body UV overlap; do not infer weapon regions from UVs")
    provenance = json.loads((ROOT / "assets/prototypes/warden-meshy-ab/provenance.json").read_text())
    return {
        "observation": "UV-matched original blade weights; not a visual-quality score or complete deformation analysis",
        "source_blade_vertices": len(blade),
        "local": {"bones": 21, "durations": [2.0, 1.0, 1.4], "blade": blade_weight_report(ROOT / "assets/prototypes/warden-rig/warden_rig.glb", blade_uvs)},
        "meshy": {"bones": provenance["animation_inventory"]["bones"], "durations": provenance["native_durations"], "blade": blade_weight_report(ROOT / "assets/prototypes/warden-meshy-ab/animations.glb", blade_uvs)},
        "credits": provenance["costs"],
    }


if __name__ == "__main__":
    report = analyze()
    output = ROOT / "builds/validation/warden-ab-asset-metrics.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
