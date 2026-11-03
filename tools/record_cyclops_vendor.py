"""Offline record of the pinned Cyclops archive and explicit local integration patch."""

import argparse
import difflib
import hashlib
import json
from pathlib import Path
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ARCHIVE_SHA256 = "ea6d7a018e596d4a7c33657513622b2acd9c21b7590b764c9d62f6db7144517e"
TEXT_TYPES = {".gd", ".tscn", ".tres", ".gdshader", ".cfg", ".md", ".txt", ".uid", ".py", ".svg", ".obj", ".mtl"}


def canonical(path, data):
    return data.replace(b"\r\n", b"\n") if Path(path).suffix in TEXT_TYPES else data


def digest(path, data):
    return hashlib.sha256(canonical(path, data)).hexdigest()


def write_new(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        if path.read_bytes() != data:
            raise FileExistsError(f"Different existing record preserved: {path}")
    else:
        path.write_bytes(data)


def record(archive):
    data = archive.read_bytes()
    if hashlib.sha256(data).hexdigest() != ARCHIVE_SHA256:
        raise ValueError("Not the pinned official Cyclops 1.5.2 release archive")
    upstream, patched, patch = {}, {}, []
    with zipfile.ZipFile(archive) as source:
        for info in source.infolist():
            name = info.filename
            if info.is_dir() or not name.startswith("addons/cyclops_level_builder/") or name.endswith((".import", ".tmp")):
                continue
            original = source.read(name)
            local = (ROOT / name).read_bytes()
            upstream[name] = digest(name, original)
            if digest(name, original) != digest(name, local):
                patched[name] = digest(name, local)
                if Path(name).suffix != ".gd":
                    raise ValueError(f"Unexpected modified vendor asset: {name}")
                patch.extend(difflib.unified_diff(original.decode().splitlines(True), local.decode().splitlines(True), fromfile="a/" + name, tofile="b/" + name))
    manifest = {
        "version": "1.5.2", "godot": "4.7.2", "date": "2026-11-03",
        "source": "https://github.com/blackears/cyclopsLevelBuilder/releases/tag/v1.5.2",
        "archive_url": "https://github.com/blackears/cyclopsLevelBuilder/releases/download/v1.5.2/cyclops_level_builder_1.5.2_for_Godot_4.7.zip",
        "archive_bytes": len(data), "archive_sha256": ARCHIVE_SHA256,
        "license": "MIT; bundled Roboto font license retained in art/fonts/Roboto/LICENSE.txt",
        "hash_note": "Text extensions use LF canonical hashes; Godot-regenerated .import files are excluded from source fingerprinting.",
        "local_patch": "docs/third-party/cyclops-1.5.2-cinderkeep.patch",
        "patch_reasons": ["Editor-owned drawing root instead of project autoload", "Dispose unused editor panels/action dialogs/snapping helper", "Skip GPU thumbnail readback in headless mode", "Weak topology backlinks prevent temporary convex-volume reference cycles"],
        "upstream_file_sha256": dict(sorted(upstream.items())),
        "patched_file_sha256": dict(sorted(patched.items())),
    }
    write_new(ROOT / "docs/third-party/cyclops-1.5.2.json", (json.dumps(manifest, indent=2) + "\n").encode())
    write_new(ROOT / manifest["local_patch"], "".join(patch).encode())
    print(f"Recorded {len(upstream)} vendor source/assets; {len(patched)} explicitly patched scripts.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    record(parser.parse_args().archive)
