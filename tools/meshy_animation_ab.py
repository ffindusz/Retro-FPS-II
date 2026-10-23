"""Fixed 14-credit Warden trial. Authoring-only; never used by the game.

Only --submit permits the two authorized POSTs. Ambiguous/failed paid tasks are
never replaced. Credentials, upload data and signed URLs are never checkpointed.
"""

import argparse
import base64
from contextlib import contextmanager
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

PROJECT = Path(__file__).resolve().parents[1]
SOURCE = PROJECT / "assets/models/enemy-warden/model.glb"
SOURCE_SHA256 = "969cef958b48e06ce33e40d8efef62797a6cba104a045e4253ac16175135e2d4"
LIMIT = 14
ACTIONS = [0, 21, 219]
EXPECTED_KEYS = {0: "Idle", 21: "Walk_Fight_Forward", 219: "Right_Hand_Sword_Slash"}
COSTS = {"rig": 5, "animate": 9}
ROUTES = {"rig": "/openapi/v1/rigging", "animate": "/openapi/v1/animations"}
STAGE = Path(os.environ.get("LOCALAPPDATA", ".")) / "Temp/opencode/cinderkeep-warden-meshy-ab-2026-10-23"
ID_PATTERN = r"[A-Za-z0-9_-]{8,100}"


def checksum(path):
    with Path(path).open("rb") as source:
        return hashlib.file_digest(source, "sha256").hexdigest()


def validate_request(path, body):
    if body is None:
        if path in ("/openapi/v1/balance", "/openapi/v1/animations/library?action_ids=0,21,219"):
            return
        if re.fullmatch(r"/openapi/v1/(?:rigging|animations)/" + ID_PATTERN, path):
            return
        raise SafeError("Unapproved read route")
    if path == ROUTES["rig"] and set(body) == {"model_url", "height_meters"}:
        if body["height_meters"] != 1.8063 or not str(body["model_url"]).startswith("data:model/gltf-binary;base64,"):
            raise SafeError("Only the authorized original Warden/height may be uploaded")
        try:
            source = base64.b64decode(body["model_url"].split(",", 1)[1], validate=True)
        except (ValueError, TypeError):
            raise SafeError("Invalid source data URI") from None
        if hashlib.sha256(source).hexdigest() != SOURCE_SHA256:
            raise SafeError("Upload source checksum mismatch")
        return
    if path == ROUTES["animate"] and set(body) == {"rig_task_id", "action_ids"}:
        if body["action_ids"] == ACTIONS and re.fullmatch(ID_PATTERN, str(body["rig_task_id"])):
            return
    raise SafeError("Unapproved paid route, source or action selection")


def api_request(key, path, body=None):
    validate_request(path, body)
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


def preflight(key):
    balance = api_request(key, "/openapi/v1/balance")["balance"]
    if not isinstance(balance, (int, float)) or balance < 0:
        raise SafeError("Invalid balance response")
    library = api_request(key, "/openapi/v1/animations/library?action_ids=0,21,219")
    if not isinstance(library, list):
        raise SafeError("Unexpected live library response")
    entries = {entry.get("action_id"): entry for entry in library}
    for action, expected in EXPECTED_KEYS.items():
        if action not in entries or entries[action].get("key") != expected:
            raise SafeError("An authorized preset is unavailable or changed; no substitute will be submitted")
    return {"balance": balance, "actions": [{field: entries[action][field] for field in ("action_id", "name", "key")} for action in ACTIONS]}


def new_record(info):
    if checksum(SOURCE) != SOURCE_SHA256:
        raise SafeError("Original source checksum mismatch")
    return {
        "authorization": {"date": "2026-10-23", "ceiling_credits": LIMIT, "source_upload_approved": True, "paid_retries": False},
        "source_sha256": SOURCE_SHA256, "source_bytes": SOURCE.stat().st_size, "height_meters": 1.8063,
        "action_ids": ACTIONS, "library": info["actions"], "balance_before": info["balance"],
        "created_at_utc": datetime.now(timezone.utc).isoformat(),
        "rights_basis": "User-confirmed paid monthly plan 2026-10-20; terms 2026-09-19 sections 2.4, 3.1, 3.2; Service Assets retained within output; no exclusive-rights guarantee",
        "stages": {},
    }


def validate_record(record):
    if record.get("source_sha256") != SOURCE_SHA256 or record.get("action_ids") != ACTIONS or record.get("authorization", {}).get("ceiling_credits") != LIMIT:
        raise SafeError("Saved authorization/source/actions do not match this fixed trial")
    stages = record.get("stages", {})
    if not set(stages).issubset(COSTS):
        raise SafeError("Unexpected paid stage in record")
    for name, stage in stages.items():
        if stage.get("reserved_credits") != COSTS[name]:
            raise SafeError("Invalid saved reservation")
        if "id" in stage and not re.fullmatch(ID_PATTERN, str(stage["id"])):
            raise SafeError("Invalid saved task ID")
    if sum(stage["reserved_credits"] for stage in stages.values()) > LIMIT:
        raise SafeError("Saved reservations exceed the authorized budget")


def check_charge(stage, expected):
    charge = stage.get("consumed_credits")
    if not isinstance(charge, int) or isinstance(charge, bool) or not 0 <= charge <= expected:
        raise SafeError("Missing/unexpected reported charge; stop before any further paid request")


def existing_download(stage, directory):
    asset = stage.get("download")
    if not asset:
        return False
    if asset.get("file") not in ("rigged.glb", "animations.glb"):
        raise SafeError("Invalid saved download filename")
    path = directory / asset["file"]
    if path.name not in ("rigged.glb", "animations.glb") or path.stat().st_size != asset["bytes"] or checksum(path) != asset["sha256"]:
        raise SafeError("Saved downloaded output differs; preserving it for review")
    return True


def run_stage(key, record, directory, name, submit=False, request=api_request, downloader=download, wait=time.sleep):
    validate_record(record)
    directory = Path(directory)
    path = directory / "record.json"
    stage = record["stages"].get(name)
    if stage and stage.get("status") in {"FAILED", "CANCELED"}:
        raise SafeError("Prior task failed/canceled; no replacement paid task is authorized")
    if stage and not stage.get("id"):
        raise SafeError("Prior submission outcome is ambiguous; reconcile it without repeating the POST")
    if stage and stage.get("status") == "SUCCEEDED" and existing_download(stage, directory):
        check_charge(stage, COSTS[name])
        print(name + ": verified cached output; no request needed", flush=True)
        return
    if not stage:
        if not submit:
            raise SafeError("Missing stage; explicit --submit is required")
        if name == "animate":
            rig = record["stages"].get("rig", {})
            if rig.get("status") != "SUCCEEDED" or not rig.get("id"):
                raise SafeError("Successful saved rig is required before animation")
            check_charge(rig, COSTS["rig"])
        remaining = sum(cost for item, cost in COSTS.items() if item not in record["stages"])
        balance = request(key, "/openapi/v1/balance")["balance"]
        if balance < remaining:
            raise SafeError("Insufficient balance for the remaining authorized stages")
        if name == "rig":
            source = SOURCE.read_bytes()
            if hashlib.sha256(source).hexdigest() != SOURCE_SHA256:
                raise SafeError("Original Warden differs; refusing upload")
            body = {"model_url": "data:model/gltf-binary;base64," + base64.b64encode(source).decode("ascii"), "height_meters": 1.8063}
        else:
            body = {"rig_task_id": record["stages"]["rig"]["id"], "action_ids": ACTIONS}
        stage = {"submission": "SUBMITTING", "reserved_credits": COSTS[name]}
        record["stages"][name] = stage
        save_record(path, record)
        try:
            response = request(key, ROUTES[name], body)
            task_id = response.get("result")
            if not isinstance(task_id, str) or not re.fullmatch(ID_PATTERN, task_id):
                raise SafeError("Submission returned no usable task ID")
            stage.update({"id": task_id, "submission": "CONFIRMED"})
            save_record(path, record)
        except BaseException:
            stage["submission"] = "UNKNOWN"
            save_record(path, record)
            raise
        print(f"{name}: task ID saved; reserved {COSTS[name]} credits", flush=True)
    previous = None
    while True:
        task = request(key, ROUTES[name] + "/" + stage["id"])
        if task.get("id") != stage["id"] or task.get("status") not in {"PENDING", "IN_PROGRESS", "SUCCEEDED", "FAILED", "CANCELED"}:
            raise SafeError("Unexpected task identity/status; response details suppressed")
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
        raise SafeError("Remote task failed/canceled; inspect the saved ID. No paid retry will be made")
    check_charge(stage, COSTS[name])
    if not existing_download(stage, directory):
        filename = "rigged.glb" if name == "rig" else "animations.glb"
        destination = directory / filename
        if destination.exists():
            raise SafeError("Unrecorded existing output preserved; reconcile before downloading")
        field = "rigged_character_glb_url" if name == "rig" else "animation_glb_url"
        url = task.get("result", {}).get(field)
        if not url:
            raise SafeError("Successful task has no required GLB result")
        stage["download"] = downloader(url, destination, glb=True)
        save_record(path, record)
    print(f"{name}: downloaded/verified; reported cost {stage['consumed_credits']} credits", flush=True)


@contextmanager
def trial_lock(directory):
    directory.mkdir(parents=True, exist_ok=True)
    lock = directory / "trial.lock"
    try:
        with lock.open("x") as target:
            target.write(str(os.getpid()))
    except FileExistsError:
        raise SafeError("A trial lock already exists; inspect saved state/process before any submission") from None
    try:
        yield
    finally:
        lock.unlink()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("stage", choices=["preflight", "rig", "animate", "run"])
    parser.add_argument("--submit", action="store_true")
    parser.add_argument("--budget", type=int, default=LIMIT)
    args = parser.parse_args()
    if args.budget != LIMIT:
        raise SafeError("Only the agreed 14-credit ceiling is supported")
    key = read_key()
    info = preflight(key)
    print(json.dumps(info, indent=2), flush=True)
    if args.stage == "preflight":
        return
    with trial_lock(STAGE):
        path = STAGE / "record.json"
        record = json.loads(path.read_text(encoding="utf-8")) if path.exists() else new_record(info)
        validate_record(record)
        save_record(path, record)
        for name in (list(COSTS) if args.stage == "run" else [args.stage]):
            run_stage(key, record, STAGE, name, args.submit)
        record["balance_after"] = api_request(key, "/openapi/v1/balance")["balance"]
        record["reported_total_credits"] = sum(stage.get("consumed_credits", 0) for stage in record["stages"].values())
        save_record(path, record)
        print(f"Saved external results: {STAGE}; reported total {record['reported_total_credits']} / {LIMIT} credits", flush=True)


if __name__ == "__main__":
    try:
        main()
    except SafeError as error:
        print("STOP:", error, file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("STOP: local interruption; inspect saved task IDs before resuming", file=sys.stderr)
        sys.exit(130)
    except Exception:
        print("STOP: unexpected error; details suppressed to protect credentials. Inspect saved state; do not retry paid POSTs.", file=sys.stderr)
        sys.exit(1)
