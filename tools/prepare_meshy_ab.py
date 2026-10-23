"""Offline inspection/import of the completed, authorized Warden Meshy trial."""

from collections import Counter
import hashlib
import json
from pathlib import Path
import shutil

from meshy_animation_ab import ACTIONS, PROJECT, SOURCE, SOURCE_SHA256, STAGE, checksum, validate_record
from warden_rig_geometry import accessor_values, read_glb


def inventory(path):
    document, binary = read_glb(path)
    primitive = document["meshes"][0]["primitives"][0]
    positions = accessor_values(document, binary, primitive["attributes"]["POSITION"])
    uvs = accessor_values(document, binary, primitive["attributes"]["TEXCOORD_0"])
    images = []
    for image in document.get("images", []):
        view = document["bufferViews"][image["bufferView"]]
        start = view.get("byteOffset", 0)
        images.append(hashlib.sha256(binary[start:start + view["byteLength"]]).hexdigest())
    clips = {}
    for animation in document.get("animations", []):
        clips[animation["name"]] = max(accessor_values(document, binary, sampler["input"])[-1][0] for sampler in animation["samplers"])
    return {
        "vertices": len(positions), "triangles": len(accessor_values(document, binary, primitive["indices"])) // 3,
        "bones": len(document["skins"][0]["joints"]) if document.get("skins") else 0,
        "bone_names": [document["nodes"][node].get("name", "") for skin in document.get("skins", []) for node in skin["joints"]],
        "clips": clips, "image_sha256": images,
        "position_min": [min(p[axis] for p in positions) for axis in range(3)],
        "position_max": [max(p[axis] for p in positions) for axis in range(3)],
    }, uvs


def main():
    record = json.loads((STAGE / "record.json").read_text(encoding="utf-8"))
    validate_record(record)
    if record.get("reported_total_credits") != 14 or record.get("balance_before") - record.get("balance_after") != 14:
        raise ValueError("Unexpected trial spend/balance; review before prototype import")
    for name in ("rig", "animate"):
        stage = record["stages"][name]
        asset = stage["download"]
        if stage["status"] != "SUCCEEDED" or checksum(STAGE / asset["file"]) != asset["sha256"]:
            raise ValueError("Incomplete or changed raw trial output")
    if checksum(SOURCE) != SOURCE_SHA256:
        raise ValueError("Original source changed")
    original, source_uv = inventory(SOURCE)
    rig, _ = inventory(STAGE / "rigged.glb")
    animated, output_uv = inventory(STAGE / "animations.glb")
    names = ["Idle", "Walk_Fight_Forward", "Right_Hand_Sword_Slash"]
    if set(animated["clips"]) != set(names) or animated["bones"] < 1:
        raise ValueError("Required three actual skeletal clips are missing")
    source_uv_set = Counter(tuple(round(value, 5) for value in uv) for uv in source_uv)
    output_uv_set = Counter(tuple(round(value, 5) for value in uv) for uv in output_uv)
    compatible = source_uv_set == output_uv_set and bool(set(original["image_sha256"]) & set(animated["image_sha256"]))
    destination = PROJECT / "assets/prototypes/warden-meshy-ab"
    destination.mkdir(parents=True, exist_ok=True)
    target = destination / "animations.glb"
    if target.exists() and checksum(target) != record["stages"]["animate"]["download"]["sha256"]:
        raise ValueError("Different existing comparison asset preserved")
    if not target.exists():
        shutil.copyfile(STAGE / "animations.glb", target)
    provenance = {
        "date": "2026-10-23", "source": "assets/models/enemy-warden/model.glb", "source_sha256": SOURCE_SHA256,
        "local_rig_sha256": checksum(PROJECT / "assets/prototypes/warden-rig/warden_rig.glb"),
        "authorization": record["authorization"], "action_ids": ACTIONS,
        "rig_task_id": record["stages"]["rig"]["id"], "animation_task_id": record["stages"]["animate"]["id"],
        "costs": {"rig": 5, "animation": 9, "total": 14}, "balance_before": record["balance_before"], "balance_after": record["balance_after"],
        "rig_download": record["stages"]["rig"]["download"], "animation_download": record["stages"]["animate"]["download"],
        "external_stage": "%LOCALAPPDATA%/Temp/opencode/cinderkeep-warden-meshy-ab-2026-10-23",
        "rights_basis": record["rights_basis"], "terms_url": "https://www.meshy.ai/terms-of-use", "terms_version": "2026-09-19",
        "rig_inventory": rig, "animation_inventory": animated,
        "clip_names": names, "native_durations": [animated["clips"][name] for name in names],
        "uv_inventory_matches_original": source_uv_set == output_uv_set,
        "use_original_material": compatible,
        "presentation": {"height_meters": 1.8063, "meshy_yaw_radians": 3.141592653589793, "rest_xz_centering": True},
        "gameplay_integration": False,
        "comparison_limits": ["Different rigs/weights: pipeline comparison, not isolated motion quality", "Native timing is default; optional phase matching is retiming", "Optional linear XZ cycle compensation is labelled; raw playback remains available", "No assumed Meshy attack contact time or automatic quality winner"],
    }
    path = destination / "provenance.json"
    serialized = json.dumps(provenance, indent=2) + "\n"
    if path.exists() and path.read_text(encoding="utf-8") != serialized:
        raise ValueError("Different existing comparison provenance preserved")
    if not path.exists():
        path.write_text(serialized, encoding="utf-8")
    print(json.dumps(provenance, indent=2))


if __name__ == "__main__":
    main()
