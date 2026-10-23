"""One fixed 90-credit pilot. No automatic paid retries or extra candidates.

Generate the three candidates first. --candidate explicitly gates the one
downstream branch; once reserved, that winner cannot be changed.
"""

import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import time
import urllib.error
import urllib.request

from meshy_generate import NoRedirect, SafeError, download, read_key, save_record, snapshot
from meshy_animation_ab import ID_PATTERN, check_charge, checksum, trial_lock

PROJECT = Path(__file__).resolve().parents[1]
PLAN_PATH = PROJECT / "docs/warden-pilot-plan.json"
STAGE = Path(os.environ.get("LOCALAPPDATA", ".")) / "Temp/opencode/cinderkeep-warden-pilot-2026-10-23"
CANDIDATES = ("c01", "c02", "c03")
COSTS = {"c01": 20, "c02": 20, "c03": 20, "texture": 10, "rig": 5, "animate": 15}
ACTIONS = [0, 21, 219, 178, 8]
TEXT_ROUTE = "/openapi/v2/text-to-3d"
LIBRARY_ROUTE = "/openapi/v1/animations/library?action_ids=0,21,219,178,8"


def load_plan():
    plan = json.loads(PLAN_PATH.read_text(encoding="utf-8"))
    if plan["maximum_credits"] != 90 or plan["costs"] != COSTS or [a["id"] for a in plan["actions"]] != ACTIONS:
        raise SafeError("Plan budget/stages/actions differ from the approved pilot")
    if [c["id"] for c in plan["candidates"]] != list(CANDIDATES) or plan["model"] != "meshy-7.1" or plan["pose_mode"] != "a-pose" or plan["geometry_resolution"] != "standard" or plan["target_polycount"] != 8000 or plan["height_meters"] != 1.8063:
        raise SafeError("Plan geometry/candidates differ from the approved pilot")
    if any(len(c["prompt"]) > 800 for c in plan["candidates"]) or len(plan["texture_prompt"]) > 800:
        raise SafeError("A prompt exceeds the API limit")
    return plan


def plan_hash(plan):
    return hashlib.sha256(json.dumps(plan, sort_keys=True, separators=(",", ":")).encode()).hexdigest()


def preview_body(plan, name):
    candidate = next(c for c in plan["candidates"] if c["id"] == name)
    return {"mode": "preview", "prompt": candidate["prompt"], "ai_model": plan["model"], "model_type": "standard", "geometry_resolution": "standard", "should_remesh": True, "topology": "triangle", "target_polycount": 8000, "pose_mode": "a-pose", "target_formats": ["glb"]}


def validate_request(path, body, plan):
    if body is None:
        if path in ("/openapi/v1/balance", LIBRARY_ROUTE) or re.fullmatch(r"/openapi/v(?:2/text-to-3d|1/(?:rigging|animations))/" + ID_PATTERN, path):
            return
    elif path == TEXT_ROUTE:
        if any(body == preview_body(plan, name) for name in CANDIDATES):
            return
        expected = {"mode", "preview_task_id", "ai_model", "enable_pbr", "texture_resolution", "texture_prompt", "target_formats"}
        if set(body) == expected and body["mode"] == "refine" and re.fullmatch(ID_PATTERN, str(body["preview_task_id"])) and body["ai_model"] == "meshy-7.1" and body["enable_pbr"] is True and body["texture_resolution"] == "2k" and body["texture_prompt"] == plan["texture_prompt"] and body["target_formats"] == ["glb"]:
            return
    elif path == "/openapi/v1/rigging" and set(body) == {"input_task_id", "height_meters"}:
        if re.fullmatch(ID_PATTERN, str(body["input_task_id"])) and body["height_meters"] == 1.8063:
            return
    elif path == "/openapi/v1/animations" and set(body) == {"rig_task_id", "action_ids"}:
        if re.fullmatch(ID_PATTERN, str(body["rig_task_id"])) and body["action_ids"] == ACTIONS:
            return
    raise SafeError("Unapproved pilot route or request parameters")


def api_request(key, path, body=None):
    validate_request(path, body, load_plan())
    payload = None if body is None else json.dumps(body).encode("utf-8")
    request = urllib.request.Request("https://api.meshy.ai" + path, data=payload, headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"})
    try:
        with urllib.request.build_opener(NoRedirect()).open(request, timeout=180 if body else 60) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        raise SafeError(f"Meshy HTTP {error.code}; details suppressed. Do not repeat a paid POST.") from None
    except (OSError, ValueError):
        raise SafeError("Meshy request did not complete; inspect checkpoints; details suppressed") from None


def preflight(key, plan, request=api_request):
    balance = request(key, "/openapi/v1/balance")["balance"]
    library = request(key, LIBRARY_ROUTE)
    entries = {entry["action_id"]: entry for entry in library}
    for action in plan["actions"]:
        if action["id"] not in entries or entries[action["id"]].get("key") != action["key"]:
            raise SafeError("A planned preset is missing/changed; no substitute will be requested")
    return {"balance": balance, "actions": [{field: entries[a["id"]][field] for field in ("action_id", "key", "name")} for a in plan["actions"]]}


def new_record(plan, info):
    return {"authorization": {"date": "2026-10-23", "maximum_credits": 90, "paid_retries": False}, "plan_sha256": plan_hash(plan), "plan": plan, "balance_before": info["balance"], "library": info["actions"], "selected": None, "stages": {}, "created_at_utc": datetime.now(timezone.utc).isoformat()}


def validate_record(record, plan):
    if record.get("plan_sha256") != plan_hash(plan) or record.get("authorization", {}).get("maximum_credits") != 90 or record.get("selected") not in (None, *CANDIDATES):
        raise SafeError("Saved plan/authorization/selection mismatch")
    if not set(record.get("stages", {})).issubset(COSTS):
        raise SafeError("Unexpected pilot stage")
    if any(name in record["stages"] for name in ("texture", "rig", "animate")) and record.get("locked_selection") != record.get("selected"):
        raise SafeError("Saved downstream selection lock differs; preserve/reconcile the record")
    for name, stage in record["stages"].items():
        if stage.get("reserved_credits") != COSTS[name] or (stage.get("id") and not re.fullmatch(ID_PATTERN, str(stage["id"]))):
            raise SafeError("Invalid saved reservation/task ID")
    if sum(stage["reserved_credits"] for stage in record["stages"].values()) > 90:
        raise SafeError("Pilot reservation ceiling exceeded")


def select_candidate(record, name):
    if name not in CANDIDATES:
        raise SafeError("Invalid candidate selection")
    if record.get("selected") not in (None, name) and any(stage in record["stages"] for stage in ("texture", "rig", "animate")):
        raise SafeError("Downstream spend locks the selected candidate; no second branch authorized")
    if any(record["stages"].get(item, {}).get("status") != "SUCCEEDED" for item in CANDIDATES):
        raise SafeError("Inspect all three successful previews before downstream selection")
    record["selected"] = name


def request_for(record, plan, name):
    if name in CANDIDATES:
        return TEXT_ROUTE, preview_body(plan, name)
    selected = record.get("selected")
    if selected not in CANDIDATES:
        raise SafeError("Explicit candidate selection is required")
    previous = selected if name == "texture" else "texture" if name == "rig" else "rig"
    parent = record["stages"].get(previous, {})
    if parent.get("status") != "SUCCEEDED" or not parent.get("id"):
        raise SafeError("Required predecessor stage has not succeeded")
    check_charge(parent, COSTS[previous])
    if name == "texture":
        return TEXT_ROUTE, {"mode": "refine", "preview_task_id": parent["id"], "ai_model": "meshy-7.1", "enable_pbr": True, "texture_resolution": "2k", "texture_prompt": plan["texture_prompt"], "target_formats": ["glb"]}
    if name == "rig":
        return "/openapi/v1/rigging", {"input_task_id": parent["id"], "height_meters": 1.8063}
    if name == "animate":
        return "/openapi/v1/animations", {"rig_task_id": parent["id"], "action_ids": ACTIONS}
    raise SafeError("Unknown stage")


def valid_download(stage, directory, name):
    asset = stage.get("download")
    if not asset:
        return False
    if asset.get("file") != name + ".glb":
        raise SafeError("Invalid saved output filename")
    path = Path(directory) / asset["file"]
    if not path.is_file() or checksum(path) != asset["sha256"] or path.stat().st_size != asset["bytes"]:
        raise SafeError("Existing output changed/missing; preserve/reconcile it before resuming")
    return True


def run_stage(key, record, plan, directory, name, submit=False, request=api_request, downloader=download, wait=time.sleep):
    validate_record(record, plan)
    path = Path(directory) / "record.json"
    stage = record["stages"].get(name)
    if stage and stage.get("status") in ("FAILED", "CANCELED"):
        raise SafeError("Prior stage failed/canceled; no automatic paid replacement")
    if stage and not stage.get("id"):
        raise SafeError("Ambiguous prior submission; reconcile it without a replacement POST")
    if stage and stage.get("status") == "SUCCEEDED" and valid_download(stage, directory, name):
        check_charge(stage, COSTS[name])
        print(name + ": verified cached result", flush=True)
        return
    route, body = request_for(record, plan, name)
    if not stage:
        if not submit:
            raise SafeError("Missing stage requires explicit --submit")
        remaining = 90 - sum(item["reserved_credits"] for item in record["stages"].values())
        if request(key, "/openapi/v1/balance")["balance"] < remaining:
            raise SafeError("Insufficient balance for the authorized remaining pilot")
        stage = {"submission": "SUBMITTING", "reserved_credits": COSTS[name]}
        if name not in CANDIDATES:
            record["locked_selection"] = record["selected"]
        record["stages"][name] = stage
        save_record(path, record)
        try:
            response = request(key, route, body)
            task_id = response.get("result")
            if not isinstance(task_id, str) or not re.fullmatch(ID_PATTERN, task_id):
                raise SafeError("No usable task ID returned")
            stage.update({"id": task_id, "submission": "CONFIRMED"})
            save_record(path, record)
        except BaseException:
            stage["submission"] = "UNKNOWN"
            save_record(path, record)
            raise
        print(f"{name}: ID saved; reserved {COSTS[name]} credits", flush=True)
    previous = None
    while True:
        task = request(key, route + "/" + stage["id"])
        if task.get("id") != stage["id"] or task.get("status") not in {"PENDING", "IN_PROGRESS", "SUCCEEDED", "FAILED", "CANCELED"}:
            raise SafeError("Unexpected task identity/status; details suppressed")
        stage.update(snapshot(task))
        save_record(path, record)
        current = (stage.get("status"), stage.get("progress"))
        if current != previous:
            print(f"{name}: {current[0]} {current[1]}%", flush=True)
            previous = current
        if stage.get("status") in {"SUCCEEDED", "FAILED", "CANCELED"}:
            break
        wait(5)
    if stage["status"] != "SUCCEEDED":
        raise SafeError("Remote stage failed/canceled; no paid replacement will be made")
    check_charge(stage, COSTS[name])
    if not valid_download(stage, directory, name):
        destination = Path(directory) / (name + ".glb")
        if destination.exists():
            raise SafeError("Unrecorded existing output preserved")
        if name in CANDIDATES or name == "texture":
            url = task.get("model_urls", {}).get("glb")
        else:
            url = task.get("result", {}).get("rigged_character_glb_url" if name == "rig" else "animation_glb_url")
        if not url:
            raise SafeError("Required GLB result missing")
        stage["download"] = downloader(url, destination, glb=True)
        save_record(path, record)
    print(f"{name}: verified download, actual charge {stage['consumed_credits']}", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("phase", choices=["preflight", "candidates", "finish"])
    parser.add_argument("--submit", action="store_true")
    parser.add_argument("--candidate", choices=CANDIDATES)
    parser.add_argument("--budget", type=int, default=90)
    args = parser.parse_args()
    if args.budget != 90:
        raise SafeError("Only the authorized 90-credit ceiling is supported")
    plan = load_plan()
    key = read_key()
    info = preflight(key, plan)
    print(json.dumps(info, indent=2), flush=True)
    if args.phase == "preflight":
        return
    with trial_lock(STAGE):
        path = STAGE / "record.json"
        record = json.loads(path.read_text(encoding="utf-8")) if path.exists() else new_record(plan, info)
        validate_record(record, plan)
        if args.phase == "finish":
            select_candidate(record, args.candidate or record.get("selected"))
        save_record(path, record)
        for name in (CANDIDATES if args.phase == "candidates" else ("texture", "rig", "animate")):
            run_stage(key, record, plan, STAGE, name, args.submit)
        balance = api_request(key, "/openapi/v1/balance")["balance"]
        record.setdefault("balance_milestones", {}).setdefault(args.phase, balance)
        record["reported_total_credits"] = sum(item.get("consumed_credits", 0) for item in record["stages"].values())
        save_record(path, record)
        print(f"Phase complete: {record['reported_total_credits']} / 90 credits used; balance {balance}; files {STAGE}", flush=True)


if __name__ == "__main__":
    try:
        main()
    except SafeError as error:
        print("STOP:", error, file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("STOP: local interruption; saved tasks continue remotely. Inspect checkpoints before resuming.", file=sys.stderr)
        sys.exit(130)
    except Exception:
        print("STOP: unexpected error; details suppressed for credential safety. Inspect saved task state; do not repeat paid requests.", file=sys.stderr)
        sys.exit(1)
