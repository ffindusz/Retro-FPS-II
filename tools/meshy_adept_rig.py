"""Bounded Meshy rig + animation run for the existing Adept. Authoring-only; never used by the game.

User authorization (2026-11-03): at most 40 credits, no paid retries.

Phases:
  library            read-only: balance and animation-library search (no spend)
  preflight          read-only: verify the plan's action IDs/keys are still in the library
  run [--submit]     rig (5) then animate (15); POSTs only with --submit

Exactly one rig submission is ever made. It uses the Adept's recorded Meshy refine
task, or, only if --upload is given, the checksum-verified local GLB as a data URI.
Ambiguous or failed paid stages are never replaced. Credentials, upload data and
signed URLs are never written to disk.
"""

import argparse
import base64
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
PLAN_PATH = PROJECT / "docs/adept-rig-plan.json"
SOURCE = PROJECT / "assets/models/enemy-adept/model.glb"
SOURCE_SHA256 = "32c0f4108f64ec007d76fd1d1f53f7ef6650216ad9d4c31aa62b4e2e911bd53c"
REFINE_TASK = "01a15a18-22aa-76bd-a5dc-272a0ef2da97"
HEIGHT_METERS = 2.0
CEILING = 40
COSTS = {"rig": 5, "animate": 15}
ROUTES = {"rig": "/openapi/v1/rigging", "animate": "/openapi/v1/animations"}
LIBRARY_ROUTE = "/openapi/v1/animations/library"
STAGE = Path(os.environ.get("LOCALAPPDATA", ".")) / "Temp/opencode/cinderkeep-adept-rig-2026-11-03"
KEYWORDS = ("idle", "walk", "cast", "spell", "magic", "staff", "attack", "hit", "dead", "death", "die")


def load_plan():
    plan = json.loads(PLAN_PATH.read_text(encoding="utf-8"))
    actions = plan.get("actions", [])
    roles = [action.get("role") for action in actions]
    if roles != ["Idle", "Walk", "Cast", "Hit", "Death"] or any(not isinstance(a.get("id"), int) or not a.get("key") for a in actions):
        raise SafeError("Plan must list Idle, Walk, Cast, Hit and Death actions with IDs and keys")
    if plan.get("ceiling_credits") != CEILING or plan.get("costs") != COSTS or plan.get("source_sha256") != SOURCE_SHA256:
        raise SafeError("Plan ceiling/costs/source do not match the authorization")
    return plan


def action_ids(plan):
    return [action["id"] for action in plan["actions"]]


def library_route(ids):
    return LIBRARY_ROUTE + "?action_ids=" + ",".join(str(i) for i in ids)


def validate_request(path, body, plan=None):
    if body is None:
        if path in ("/openapi/v1/balance", LIBRARY_ROUTE):
            return
        if plan is not None and path == library_route(action_ids(plan)):
            return
        if re.fullmatch(r"/openapi/v1/(?:rigging|animations)/" + ID_PATTERN, path):
            return
        raise SafeError("Unapproved read route")
    if path == ROUTES["rig"] and set(body) == {"input_task_id", "height_meters"}:
        if body["input_task_id"] == REFINE_TASK and body["height_meters"] == HEIGHT_METERS:
            return
    if path == ROUTES["rig"] and set(body) == {"model_url", "height_meters"} and body["height_meters"] == HEIGHT_METERS:
        url = str(body["model_url"])
        if url.startswith("data:model/gltf-binary;base64,"):
            try:
                source = base64.b64decode(url.split(",", 1)[1], validate=True)
            except (ValueError, TypeError):
                raise SafeError("Invalid source data URI") from None
            if hashlib.sha256(source).hexdigest() == SOURCE_SHA256:
                return
    if path == ROUTES["animate"] and set(body) == {"rig_task_id", "action_ids"} and plan is not None:
        if body["action_ids"] == action_ids(plan) and re.fullmatch(ID_PATTERN, str(body["rig_task_id"])):
            return
    raise SafeError("Unapproved paid route, source or action selection")


def api_request(key, path, body=None, plan=None):
    validate_request(path, body, plan)
    payload = None if body is None else json.dumps(body).encode("utf-8")
    request = urllib.request.Request("https://api.meshy.ai" + path, data=payload, headers={
        "Authorization": "Bearer " + key, "Content-Type": "application/json",
    })
    try:
        with urllib.request.build_opener(NoRedirect()).open(request, timeout=180 if body else 60) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        raise SafeError(f"Meshy HTTP {error.code}; response suppressed. Do not repeat a paid submission.") from None
    except (OSError, ValueError):
        raise SafeError("Meshy request did not complete; details suppressed. Inspect saved state before any action.") from None


def search_library(key, request=api_request):
    balance = request(key, "/openapi/v1/balance")["balance"]
    library = request(key, LIBRARY_ROUTE)
    if isinstance(library, dict):
        library = library.get("result") or library.get("data") or []
    matches = []
    for entry in library:
        text = " ".join(str(entry.get(field, "")) for field in ("key", "name", "category", "subcategory")).lower()
        if any(word in text for word in KEYWORDS):
            matches.append({field: entry.get(field) for field in ("action_id", "key", "name", "category", "subcategory")})
    return {"balance": balance, "library_size": len(library), "matches": matches}


def preflight(key, plan, request=api_request):
    balance = request(key, "/openapi/v1/balance")["balance"]
    if not isinstance(balance, (int, float)) or balance < CEILING:
        raise SafeError("Balance is below the authorized ceiling; no submission")
    library = request(key, library_route(action_ids(plan)), plan=plan)
    entries = {entry.get("action_id"): entry for entry in library}
    for action in plan["actions"]:
        if entries.get(action["id"], {}).get("key") != action["key"]:
            raise SafeError("A planned action is missing/changed; no substitute will be requested")
    return {"balance": balance, "actions": plan["actions"]}


def new_record(plan, info):
    return {
        "authorization": {"date": "2026-11-03", "ceiling_credits": CEILING, "paid_retries": False},
        "source": {"file": "assets/models/enemy-adept/model.glb", "sha256": SOURCE_SHA256, "refine_task": REFINE_TASK},
        "height_meters": HEIGHT_METERS, "actions": plan["actions"], "balance_before": info["balance"],
        "stages": {}, "created_at_utc": datetime.now(timezone.utc).isoformat(),
    }


def validate_record(record):
    if record.get("authorization", {}).get("ceiling_credits") != CEILING:
        raise SafeError("Saved record ceiling mismatch")
    stages = record.get("stages", {})
    if set(stages) - set(COSTS):
        raise SafeError("Unexpected saved stage")
    for name, stage in stages.items():
        if stage.get("reserved_credits") != COSTS[name]:
            raise SafeError("Saved reservation mismatch")
    if sum(stage["reserved_credits"] for stage in stages.values()) > CEILING:
        raise SafeError("Saved reservations exceed the ceiling")


def rig_body(upload):
    if not upload:
        return {"input_task_id": REFINE_TASK, "height_meters": HEIGHT_METERS}
    data = SOURCE.read_bytes()
    if hashlib.sha256(data).hexdigest() != SOURCE_SHA256:
        raise SafeError("Local Adept GLB checksum mismatch")
    return {"model_url": "data:model/gltf-binary;base64," + base64.b64encode(data).decode("ascii"), "height_meters": HEIGHT_METERS}


def valid_download(stage, directory, name):
    asset = stage.get("download")
    if not asset:
        return False
    path = Path(directory) / asset.get("file", "")
    if asset.get("file") != name + ".glb" or not path.is_file() or path.stat().st_size != asset["bytes"] or checksum(path) != asset["sha256"]:
        raise SafeError("Existing output changed/missing; reconcile before resuming")
    return True


def run_stage(key, record, plan, directory, name, submit=False, upload=False, request=api_request, downloader=download, wait=time.sleep):
    validate_record(record)
    path = Path(directory) / "record.json"
    stage = record["stages"].get(name)
    # The single permitted fallback: a refine-task rig request that Meshy rejected before
    # creating a task (HTTP 4xx, no ID, no charge) may be replaced once by the local upload.
    if (name == "rig" and upload and stage and stage.get("submission") == "REJECTED" and not stage.get("id")
            and stage.get("route") == "refine_task" and not record.get("rejected_attempts")):
        record["rejected_attempts"] = [stage]
        del record["stages"]["rig"]
        save_record(path, record)
        stage = None
    if stage and stage.get("status") in ("FAILED", "CANCELED"):
        raise SafeError("Prior stage failed/canceled; no automatic paid replacement")
    if stage and not stage.get("id"):
        raise SafeError("Ambiguous prior submission; reconcile it without a replacement POST")
    if stage and stage.get("status") == "SUCCEEDED" and valid_download(stage, directory, name):
        check_charge(stage, COSTS[name])
        print(name + ": verified cached result", flush=True)
        return
    if not stage:
        if not submit:
            raise SafeError("Missing stage requires explicit --submit")
        if name == "animate" and record["stages"].get("rig", {}).get("status") != "SUCCEEDED":
            raise SafeError("Rig must succeed before animation")
        reserved = sum(item["reserved_credits"] for item in record["stages"].values())
        if reserved + COSTS[name] > CEILING:
            raise SafeError("Stage would exceed the authorized ceiling")
        if request(key, "/openapi/v1/balance", plan=plan)["balance"] < COSTS[name]:
            raise SafeError("Insufficient balance")
        body = rig_body(upload) if name == "rig" else {"rig_task_id": record["stages"]["rig"]["id"], "action_ids": action_ids(plan)}
        stage = {"submission": "SUBMITTING", "reserved_credits": COSTS[name], "route": "upload" if (name == "rig" and upload) else ("refine_task" if name == "rig" else "rig_task")}
        record["stages"][name] = stage
        save_record(path, record)
        try:
            response = request(key, ROUTES[name], body, plan=plan)
            task_id = response.get("result")
            if not isinstance(task_id, str) or not re.fullmatch(ID_PATTERN, task_id):
                raise SafeError("No usable task ID returned")
            stage.update({"id": task_id, "submission": "CONFIRMED"})
            save_record(path, record)
        except SafeError as error:
            # An HTTP rejection before a task ID exists is recorded as rejected (no charge expected).
            stage["submission"] = "REJECTED" if "HTTP 4" in str(error) else "UNKNOWN"
            stage["error"] = str(error)
            save_record(path, record)
            raise
        print(f"{name}: task ID saved; reserved {COSTS[name]} credits", flush=True)
    previous = None
    while True:
        task = request(key, ROUTES[name] + "/" + stage["id"], plan=plan)
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
        url = task.get("result", {}).get("rigged_character_glb_url" if name == "rig" else "animation_glb_url")
        if not url:
            raise SafeError("Required GLB result missing")
        stage["download"] = downloader(url, destination, glb=True)
        save_record(path, record)
    print(f"{name}: verified download, reported charge {stage['consumed_credits']}", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("phase", choices=["library", "preflight", "run"])
    parser.add_argument("--submit", action="store_true")
    parser.add_argument("--upload", action="store_true", help="rig from the local GLB instead of the refine task")
    args = parser.parse_args()
    key = read_key()
    if args.phase == "library":
        print(json.dumps(search_library(key), indent=2), flush=True)
        return
    plan = load_plan()
    info = preflight(key, plan)
    print(json.dumps(info, indent=2), flush=True)
    if args.phase == "preflight":
        return
    with trial_lock(STAGE):
        path = STAGE / "record.json"
        record = json.loads(path.read_text(encoding="utf-8")) if path.exists() else new_record(plan, info)
        validate_record(record)
        save_record(path, record)
        for name in ("rig", "animate"):
            run_stage(key, record, plan, STAGE, name, args.submit, args.upload)
        record["balance_after"] = api_request(key, "/openapi/v1/balance")["balance"]
        record["reported_total_credits"] = sum(item.get("consumed_credits", 0) for item in record["stages"].values())
        save_record(path, record)
        print(f"Complete: {record['reported_total_credits']} / {CEILING} credits; files {STAGE}", flush=True)


if __name__ == "__main__":
    try:
        main()
    except SafeError as error:
        print("STOP:", error, file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("STOP: local interruption; saved tasks continue remotely. Inspect checkpoints before resuming.", file=sys.stderr)
        sys.exit(1)
