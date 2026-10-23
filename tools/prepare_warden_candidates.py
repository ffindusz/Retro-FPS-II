"""Offline import/backup of completed pilot previews; no API calls or credits."""

import json
from pathlib import Path
import shutil

from inspect_glb import inspect
from meshy_warden_pilot import CANDIDATES, PROJECT, STAGE, checksum, load_plan, validate_record


def copy_verified(source, destination, expected):
    if checksum(source) != expected:
        raise ValueError("Staged source differs from its checkpoint")
    if destination.exists() and checksum(destination) != expected:
        raise ValueError(f"Different existing output preserved: {destination}")
    destination.parent.mkdir(parents=True, exist_ok=True)
    if not destination.exists():
        shutil.copy2(source, destination)


def main():
    plan = load_plan()
    record = json.loads((STAGE / "record.json").read_text(encoding="utf-8"))
    validate_record(record, plan)
    output = PROJECT / "assets/prototypes/warden-pilot/candidates"
    backup = PROJECT / "builds/authoring/warden-pilot"
    candidates = []
    for name in CANDIDATES:
        stage = record["stages"][name]
        if stage["status"] != "SUCCEEDED" or stage["consumed_credits"] > 20:
            raise ValueError("Preview did not succeed within its authorized stage")
        source = STAGE / stage["download"]["file"]
        info = inspect(source)
        if info["external_resources"] or info["skins"] or info["animations"]:
            raise ValueError("Unexpected external/animated candidate input; review before import")
        copy_verified(source, output / (name + ".glb"), stage["download"]["sha256"])
        copy_verified(source, backup / (name + ".glb"), stage["download"]["sha256"])
        item = next(c for c in plan["candidates"] if c["id"] == name)
        candidates.append({"id": name, "label": item["label"], "task_id": stage["id"], "consumed_credits": stage["consumed_credits"], "download": stage["download"], "inventory": info})
    report = {"date": "2026-10-23", "phase": "untextured body selection", "plan_sha256": record["plan_sha256"], "authorization": record["authorization"], "model": plan["model"], "pose_mode": plan["pose_mode"], "target_polycount": plan["target_polycount"], "candidates": candidates, "preview_credits": sum(c["consumed_credits"] for c in candidates), "remaining_planned_credits": 30, "rights_basis": plan["rights_basis"], "gameplay_integration": False}
    output.mkdir(parents=True, exist_ok=True)
    serialized = json.dumps(report, indent=2) + "\n"
    report_path = output / "provenance.json"
    if report_path.exists() and report_path.read_text(encoding="utf-8") != serialized:
        raise ValueError("Different existing candidate provenance preserved")
    if not report_path.exists():
        report_path.write_text(serialized, encoding="utf-8")
    # Keep immutable checkpoints for the preview milestone rather than overwriting
    # the later finished-pilot record or any user-edited backup.
    checkpoint = backup / "candidate-record.json"
    data = (STAGE / "record.json").read_bytes()
    if checkpoint.exists() and checkpoint.read_bytes() != data:
        print("Existing preview checkpoint retained; current record remains in external staging")
    elif not checkpoint.exists():
        checkpoint.write_bytes(data)
    print(json.dumps(report, indent=2))


if __name__ == "__main__":
    main()
