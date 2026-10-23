"""Offline preparation of the completed single-winner pilot; no API calls."""

from collections import Counter
import json
from pathlib import Path

from inspect_glb import inspect
from meshy_warden_pilot import CANDIDATES, COSTS, PROJECT, STAGE, checksum, load_plan, validate_record
from prepare_warden_candidates import copy_verified
from prepare_meshy_ab import inventory
from warden_rig_geometry import accessor_values, read_glb


def uv_triangles(path):
    document, binary = read_glb(path)
    primitive = document["meshes"][0]["primitives"][0]
    uvs = accessor_values(document, binary, primitive["attributes"]["TEXCOORD_0"])
    indices = [value[0] for value in accessor_values(document, binary, primitive["indices"])]
    return Counter(tuple(sorted(tuple(round(v, 5) for v in uvs[index]) for index in indices[start:start + 3])) for start in range(0, len(indices), 3))


def main():
    plan = load_plan()
    record = json.loads((STAGE / "record.json").read_text(encoding="utf-8"))
    validate_record(record, plan)
    if record.get("reported_total_credits") != 90 or record.get("selected") != record.get("locked_selection"):
        raise ValueError("Pilot is not a completed authorized single-winner branch")
    output = PROJECT / "assets/prototypes/warden-pilot/winner"
    backup = PROJECT / "builds/authoring/warden-pilot"
    stages = {}
    for name, expected_cost in COSTS.items():
        stage = record["stages"][name]
        asset = stage["download"]
        source = STAGE / asset["file"]
        if stage["status"] != "SUCCEEDED" or stage["consumed_credits"] != expected_cost or checksum(source) != asset["sha256"]:
            raise ValueError("Pilot stage missing, changed or outside its authorized charge")
        info = inspect(source)
        if info["external_resources"]:
            raise ValueError("Unexpected external resources in pilot output")
        copy_verified(source, backup / asset["file"], asset["sha256"])
        if name in ("texture", "animate"):
            copy_verified(source, output / asset["file"], asset["sha256"])
        stages[name] = {"task_id": stage["id"], "consumed_credits": stage["consumed_credits"], "download": asset, "inventory": info}
    textured, _ = inventory(STAGE / "texture.glb")
    animated, _ = inventory(STAGE / "animate.glb")
    names = [a["key"] for a in plan["actions"]]
    if set(animated["clips"]) != set(names) or "RightHand" not in animated["bone_names"]:
        raise ValueError("Pilot clips/carrying hand are missing")
    compatible = uv_triangles(STAGE / "texture.glb") == uv_triangles(STAGE / "animate.glb") and bool(set(textured["image_sha256"]) & set(animated["image_sha256"]))
    if not compatible:
        raise ValueError("Selected PBR material is not proven compatible with the animated UV atlas")
    report = {
        "date": "2026-10-23", "authorization": record["authorization"], "plan_sha256": record["plan_sha256"],
        "selected": record["selected"], "selection": "User explicitly chose 2 Brigandine after actual candidate review",
        "stages": stages, "total_credits": 90, "balance_before": record["balance_before"], "balance_milestones": record["balance_milestones"],
        "clip_names": names, "clip_roles": [a["role"] for a in plan["actions"]], "native_durations": [animated["clips"][name] for name in names],
        "textured_inventory": textured, "animated_inventory": animated,
        "pbr_atlas_triangle_uv_match": compatible,
        "material_note": "Animated export has albedo only; verified matching UV triangles and original albedo permit the selected textured body's full PBR material",
        "body_pose_note": "A-pose requested, actual previews have bent elbows; not a pose-compliance or quality guarantee",
        "hand_bone": "RightHand", "height_meters": 1.8063,
        "weapon": {"scene": "scenes/models/iron_blade.tscn", "source": "assets/models/weapon-cleaver/model.glb", "source_sha256": checksum(PROJECT / "assets/models/weapon-cleaver/model.glb"), "attachment": "Separate unskinned hand-following object, not part of body weights"},
        "rights_basis": plan["rights_basis"], "terms_url": "https://www.meshy.ai/terms-of-use", "terms_version": "2026-09-19",
        "external_stage": "%LOCALAPPDATA%/Temp/opencode/cinderkeep-warden-pilot-2026-10-23", "gameplay_integration": False,
    }
    serialized = json.dumps(report, indent=2) + "\n"
    path = output / "provenance.json"
    if path.exists() and path.read_text(encoding="utf-8") != serialized:
        raise ValueError("Different existing winner provenance preserved")
    if not path.exists():
        path.write_text(serialized, encoding="utf-8")
    checkpoint = backup / "finished-record.json"
    data = (STAGE / "record.json").read_bytes()
    if checkpoint.exists() and checkpoint.read_bytes() != data:
        raise ValueError("Different existing finished checkpoint preserved")
    if not checkpoint.exists():
        checkpoint.write_bytes(data)
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
