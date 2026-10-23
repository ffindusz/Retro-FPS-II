"""Package the exact accepted Windows build, offline and without workspace globbing."""

import argparse
import hashlib
import io
import json
from pathlib import Path
import zipfile


ARTIFACTS = ("Cinderkeep.exe", "Cinderkeep.pck")
DOCUMENTS = ("README.txt", "CREDITS.txt", "GODOT-LICENSE.txt", "GODOT-COPYRIGHT.txt")
ZIP_DATE = (2026, 10, 22, 0, 0, 0)


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def read_local(root: Path, path: Path) -> bytes:
    if path.is_symlink() or not path.resolve().is_relative_to(root.resolve()):
        raise ValueError(f"Refusing nonlocal/symlink input: {path}")
    data = path.read_bytes()
    if not data:
        raise ValueError(f"Empty package input: {path}")
    return data


def build_bundle(root: Path, output: Path) -> dict:
    release = json.loads((root / "docs/release/release-0.4.1.json").read_text(encoding="utf-8"))
    if release.get("version") != "0.4.1" or release.get("platform") != "windows-x64":
        raise ValueError("Expected the accepted 0.4.1 Windows x64 release record")
    records = release["artifacts"]
    if len(records) != 2 or {entry["name"] for entry in records} != set(ARTIFACTS):
        raise ValueError("Release record must describe exactly the two accepted artifacts")
    files = {}
    for entry in records:
        name = entry["name"]
        data = read_local(root, root / "builds/windows" / name)
        if len(data) != entry["bytes"] or digest(data) != entry["sha256"]:
            raise ValueError(f"Accepted artifact size/hash mismatch: {name}")
        files[name] = data
    for name in DOCUMENTS:
        files[name] = read_local(root, root / "docs/release" / name)
    notice_record = json.loads((root / "docs/release/engine-notices.json").read_text(encoding="utf-8"))
    if notice_record.get("engine") != release.get("engine"):
        raise ValueError("Engine notices must match the accepted release engine")
    for notice in notice_record["files"]:
        if notice["name"] not in ("GODOT-LICENSE.txt", "GODOT-COPYRIGHT.txt"):
            raise ValueError("Unexpected engine notice")
        if digest(files[notice["name"]]) != notice["sha256"]:
            raise ValueError(f"Engine notice checksum mismatch: {notice['name']}")
    if {notice["name"] for notice in notice_record["files"]} != {"GODOT-LICENSE.txt", "GODOT-COPYRIGHT.txt"}:
        raise ValueError("Both verified engine notices are required")
    checksums = {name: digest(data) for name, data in sorted(files.items())}
    files["SHA256SUMS.txt"] = "".join(f"{value}  {name}\n" for name, value in checksums.items()).encode("utf-8")
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for name, data in sorted(files.items()):
            info = zipfile.ZipInfo(name, ZIP_DATE)
            info.compress_type = zipfile.ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            archive.writestr(info, data, compresslevel=9)
    result = buffer.getvalue()
    with zipfile.ZipFile(io.BytesIO(result)) as archive:
        if archive.testzip() is not None:
            raise ValueError("Archive CRC verification failed")
        if set(archive.namelist()) != set(files):
            raise ValueError("Archive allowlist mismatch")
        for name, expected in checksums.items():
            if digest(archive.read(name)) != expected:
                raise ValueError(f"Archive checksum mismatch: {name}")
    output.parent.mkdir(parents=True, exist_ok=True)
    if output.exists():
        if output.read_bytes() != result:
            raise FileExistsError(f"Different existing bundle left untouched: {output}")
    else:
        with output.open("xb") as target:
            target.write(result)
    return {"file": str(output), "version": "0.4.1", "bytes": len(result), "sha256": digest(result), "files": checksums}


def main():
    root = Path(__file__).resolve().parents[1]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=root / "builds/releases/Cinderkeep-0.4.1-windows-x64.zip")
    args = parser.parse_args()
    print(json.dumps(build_bundle(root, args.output), indent=2))


if __name__ == "__main__":
    main()
