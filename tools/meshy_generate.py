"""Opt-in Meshy authoring only; never imported or used by the Godot runtime.

Submit each paid stage once, checkpoint its ID, and resume existing tasks rather
than silently regenerating. Credentials and signed download URLs are never saved.
"""
from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

PROJECT = Path(__file__).resolve().parent.parent
API = "https://api.meshy.ai"
TERMINAL = {"SUCCEEDED", "FAILED", "CANCELED"}


class SafeError(Exception):
    """Only explicitly credential-free messages may reach command output."""


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def read_key() -> str:
    key = os.environ.get("MESHY_API_KEY", "").strip()
    if not key:
        try:
            text = (PROJECT / ".env").read_text(encoding="utf-8-sig")
        except OSError:
            raise SafeError("No MESHY_API_KEY environment variable or readable .env.") from None
        entries = re.findall(r"^\s*(?:export\s+)?MESHY_API_KEY\s*=\s*(.*?)\s*$", text, re.M)
        if entries:
            key = entries[-1].strip()
            if len(key) >= 2 and key[0] == key[-1] and key[0] in "\"'":
                key = key[1:-1]
            else:
                key = re.split(r"\s+#", key, maxsplit=1)[0].strip()
    if not key or key in {"your_actual_key", "your_key"}:
        raise SafeError("MESHY_API_KEY is missing or a placeholder.")
    return key


def api_request(key: str, path: str, body: dict | None = None) -> dict:
    if not path.startswith(("/openapi/v1/balance", "/openapi/v2/text-to-3d")):
        raise SafeError("Unapproved API route.")
    headers = {"Authorization": "Bearer " + key, "Content-Type": "application/json"}
    payload = None if body is None else json.dumps(body).encode("utf-8")
    request = urllib.request.Request(API + path, data=payload, headers=headers)
    try:
        with urllib.request.build_opener(NoRedirect()).open(request, timeout=60 if body else 30) as response:
            return json.load(response)
    except urllib.error.HTTPError as error:
        raise SafeError(f"Meshy HTTP {error.code} for {'POST' if body else 'GET'} {path}.") from None
    except (OSError, ValueError):
        raise SafeError(f"Meshy {'submission' if body else 'read'} did not complete; credential-bearing error details suppressed.") from None


def save_record(path: Path, record: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(record, indent=2) + "\n", encoding="utf-8")
    temporary.replace(path)


def snapshot(task: dict) -> dict:
    return {name: task[name] for name in (
        "id", "status", "progress", "created_at", "started_at", "finished_at", "consumed_credits"
    ) if name in task}


def download(url: str, destination: Path, glb: bool = False) -> dict:
    parsed = urllib.parse.urlparse(url)
    if parsed.scheme != "https" or not (parsed.hostname or "").endswith(".meshy.ai") or parsed.username:
        raise SafeError("Download host is not an approved HTTPS Meshy asset host.")
    temporary = destination.with_suffix(destination.suffix + ".tmp")
    digest = hashlib.sha256()
    count = 0
    try:
        # Deliberately no Authorization header on asset downloads.
        with urllib.request.build_opener(NoRedirect()).open(url, timeout=120) as response, temporary.open("wb") as output:
            while chunk := response.read(1024 * 1024):
                count += len(chunk)
                if count > 300 * 1024 * 1024:
                    raise SafeError("Download exceeds the 300 MiB safety limit.")
                digest.update(chunk)
                output.write(chunk)
        if glb:
            with temporary.open("rb") as source:
                if source.read(4) != b"glTF":
                    raise SafeError("Downloaded model is not a GLB.")
        temporary.replace(destination)
    except (OSError, urllib.error.URLError):
        raise SafeError("Asset download failed; signed URL and error details suppressed.") from None
    return {"file": destination.name, "bytes": count, "sha256": digest.hexdigest()}


def run_asset(key: str, plan: dict, asset: dict, output: Path, stage: str, submit: bool) -> None:
    asset_dir = output / asset["id"]
    path = asset_dir / "record.json"
    record = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {
        "asset": asset, "model": plan["model"], "model_type": plan["model_type"],
        "requested_at_utc": datetime.now(timezone.utc).isoformat(),
        "rights_status": "unresolved: confirm account plan and applicable Meshy terms before distribution",
        "source_inputs": "Original text prompts only; no uploaded reference assets or personal data."
    }
    job = record.get(stage, {})
    if not job.get("id"):
        if job.get("submission") in {"SUBMITTING", "UNKNOWN"}:
            raise SafeError(f"{asset['id']} {stage}: prior POST outcome unknown. Reconcile in Meshy before any retry.")
        if not submit:
            raise SafeError(f"{asset['id']} {stage}: not submitted; --submit is required for paid requests.")
        if stage == "preview":
            body = {
                "mode": "preview", "prompt": asset["prompt"], "ai_model": plan["model"],
                "model_type": plan["model_type"], "topology": "triangle",
                "target_polycount": asset["target_polycount"], "target_formats": ["glb"]
            }
        else:
            preview = record.get("preview", {})
            if preview.get("status") != "SUCCEEDED":
                raise SafeError(f"{asset['id']}: successful preview required before refining.")
            body = {
                "mode": "refine", "preview_task_id": preview["id"], "enable_pbr": True,
                "texture_resolution": "2k", "texture_prompt": asset["texture_prompt"],
                "target_formats": ["glb"]
            }
        job = {"submission": "SUBMITTING", "request": body}
        record[stage] = job
        save_record(path, record)
        try:
            result = api_request(key, "/openapi/v2/text-to-3d", body)
            job["id"] = result["result"]
            job["submission"] = "CONFIRMED"
        except Exception:
            job["submission"] = "UNKNOWN"
            save_record(path, record)
            raise
        save_record(path, record)
        print(f"{asset['id']}: {stage} submitted ({job['id']})", flush=True)

    previous = None
    while True:
        # Read failures never trigger a replacement paid job.
        task = api_request(key, "/openapi/v2/text-to-3d/" + job["id"])
        job.update(snapshot(task))
        save_record(path, record)
        progress = (job.get("status"), job.get("progress"))
        if progress != previous:
            print(f"{asset['id']}: {stage} {progress[0]} {progress[1]}%", flush=True)
            previous = progress
        if job.get("status") in TERMINAL:
            break
        time.sleep(5)
    if job["status"] != "SUCCEEDED":
        raise SafeError(f"{asset['id']} {stage} ended {job['status']}; no automatic paid retry.")

    expected = plan[f"estimated_{stage}_credits"]
    if job.get("consumed_credits", 0) > expected:
        raise SafeError(f"{asset['id']} {stage}: reported credits exceeded estimate; stop before further paid stages.")
    # Persist exports immediately: Meshy API output has limited retention.
    model = asset_dir / ("preview.glb" if stage == "preview" else "model.glb")
    if not model.exists():
        job["model_download"] = download(task["model_urls"]["glb"], model, glb=True)
    thumbnail = asset_dir / ("preview.png" if stage == "preview" else "textured.png")
    if task.get("thumbnail_url") and not thumbnail.exists():
        job["thumbnail_download"] = download(task["thumbnail_url"], thumbnail)
    save_record(path, record)
    print(f"{asset['id']}: {stage} downloaded to {asset_dir}", flush=True)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("stage", choices=["preview", "refine", "balance"])
    parser.add_argument("--submit", action="store_true", help="Explicitly authorize missing paid tasks; otherwise resume only.")
    parser.add_argument("--output", type=Path, default=Path(os.environ.get("LOCALAPPDATA", ".")) / "Temp/opencode/cinderkeep-meshy-2026-10-20")
    parser.add_argument("--only", choices=["weapon-cleaver", "weapon-staff", "enemy-warden", "enemy-adept", "prop-torch", "prop-urn"])
    args = parser.parse_args()
    key = read_key()
    balance = api_request(key, "/openapi/v1/balance")
    print("Available Meshy credits:", balance["balance"], flush=True)
    if args.stage == "balance":
        return 0
    plan = json.loads((PROJECT / "docs/meshy-models.json").read_text(encoding="utf-8"))
    assets = [asset for asset in plan["assets"] if not args.only or asset["id"] == args.only]
    for asset in assets:
        for field in ("prompt", "texture_prompt"):
            if len(asset[field]) > 800:
                raise SafeError(f"{asset['id']} {field} exceeds Meshy's 800-character limit.")
    ceiling = len(assets) * plan[f"estimated_{args.stage}_credits"]
    if args.submit and balance["balance"] < ceiling:
        raise SafeError("Balance is below the estimated stage cost.")
    print(f"Stage {args.stage}; at most {len(assets)} assets; estimated new-stage ceiling {ceiling} credits.", flush=True)
    # Two in-flight assets keep request/queue load modest without serial generation.
    with ThreadPoolExecutor(max_workers=2) as pool:
        jobs = [pool.submit(run_asset, key, plan, asset, args.output, args.stage, args.submit) for asset in assets]
        for job in jobs:
            job.result()
    final = api_request(key, "/openapi/v1/balance")
    print("Stage complete. Available Meshy credits:", final["balance"], flush=True)
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except SafeError as error:
        print("STOP:", error, file=sys.stderr)
        sys.exit(1)
    except KeyboardInterrupt:
        print("Stopped locally. Submitted jobs continue on Meshy; resume their saved IDs.", file=sys.stderr)
        sys.exit(130)
    except Exception:
        print("STOP: unexpected error; details suppressed to protect credentials. Check saved task records before retrying.", file=sys.stderr)
        sys.exit(1)
