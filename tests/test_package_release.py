import hashlib
import json
from pathlib import Path
import sys
import tempfile
import unittest
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
from package_release import ARTIFACTS, DOCUMENTS, build_bundle


class PackageReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / "builds/windows").mkdir(parents=True)
        (self.root / "docs/release").mkdir(parents=True)
        self.output = self.root / "bundle.zip"
        entries = []
        for name in ARTIFACTS:
            data = (name + " accepted").encode()
            (self.root / "builds/windows" / name).write_bytes(data)
            entries.append({"name": name, "bytes": len(data), "sha256": hashlib.sha256(data).hexdigest()})
        self.record = self.root / "docs/release/release-0.4.1.json"
        self.record.write_text(json.dumps({"version": "0.4.1", "platform": "windows-x64", "engine": "4.7.2.stable", "artifacts": entries}))
        for name in DOCUMENTS:
            (self.root / "docs/release" / name).write_text("fixture " + name)
        notices = [{"name": name, "sha256": hashlib.sha256((self.root / "docs/release" / name).read_bytes()).hexdigest()} for name in DOCUMENTS if name.startswith("GODOT-")]
        (self.root / "docs/release/engine-notices.json").write_text(json.dumps({"engine": "4.7.2.stable", "files": notices}))

    def test_allowlist_exact_bytes_and_checksums(self):
        (self.root / "builds/windows/.env").write_text("not for distribution")
        (self.root / "builds/windows/unrelated.exe").write_bytes(b"private")
        result = build_bundle(self.root, self.output)
        with zipfile.ZipFile(self.output) as archive:
            self.assertIsNone(archive.testzip())
            self.assertEqual(set(archive.namelist()), set(ARTIFACTS + DOCUMENTS + ("SHA256SUMS.txt",)))
            for name, expected in result["files"].items():
                self.assertEqual(hashlib.sha256(archive.read(name)).hexdigest(), expected)
                self.assertIn(f"{expected}  {name}\n", archive.read("SHA256SUMS.txt").decode())

    def test_repeatable_and_identical_existing_output_is_safe(self):
        first = build_bundle(self.root, self.output)
        second = build_bundle(self.root, self.root / "again.zip")
        self.assertEqual(first["sha256"], second["sha256"])
        self.assertEqual(build_bundle(self.root, self.output), first)

    def test_changed_same_size_binary_is_rejected(self):
        path = self.root / "builds/windows/Cinderkeep.exe"
        path.write_bytes(b"x" * path.stat().st_size)
        with self.assertRaisesRegex(ValueError, "hash mismatch"):
            build_bundle(self.root, self.output)
        self.assertFalse(self.output.exists())

    def test_changed_size_is_rejected(self):
        (self.root / "builds/windows/Cinderkeep.pck").write_bytes(b"changed")
        with self.assertRaisesRegex(ValueError, "size/hash mismatch"):
            build_bundle(self.root, self.output)

    def test_existing_different_output_is_preserved(self):
        self.output.write_bytes(b"user file")
        with self.assertRaises(FileExistsError):
            build_bundle(self.root, self.output)
        self.assertEqual(self.output.read_bytes(), b"user file")

    def test_missing_notice_is_rejected(self):
        (self.root / "docs/release/GODOT-LICENSE.txt").unlink()
        with self.assertRaises(FileNotFoundError):
            build_bundle(self.root, self.output)

    def test_modified_notice_is_rejected(self):
        (self.root / "docs/release/GODOT-COPYRIGHT.txt").write_text("modified")
        with self.assertRaisesRegex(ValueError, "notice checksum mismatch"):
            build_bundle(self.root, self.output)

    def test_extra_artifact_record_is_rejected(self):
        record = json.loads(self.record.read_text())
        record["artifacts"].append({"name": "../.env"})
        self.record.write_text(json.dumps(record))
        with self.assertRaisesRegex(ValueError, "exactly"):
            build_bundle(self.root, self.output)

    def test_wrong_version_is_rejected(self):
        record = json.loads(self.record.read_text())
        record["version"] = "0.5"
        self.record.write_text(json.dumps(record))
        with self.assertRaisesRegex(ValueError, "0.4.1"):
            build_bundle(self.root, self.output)

    def test_mismatched_engine_notices_are_rejected(self):
        record = json.loads(self.record.read_text())
        record["engine"] = "different-engine"
        self.record.write_text(json.dumps(record))
        with self.assertRaisesRegex(ValueError, "match the accepted"):
            build_bundle(self.root, self.output)

    def test_real_project_keeps_prototype_out_of_exports_and_main_game(self):
        project = Path(__file__).resolve().parents[1]
        preset = (project / "export_presets.cfg").read_text()
        self.assertIn("scenes/prototypes/*", preset)
        self.assertIn("scripts/prototypes/*", preset)
        self.assertEqual(json.loads((project / "docs/release/release-0.4.1.json").read_text())["version"], "0.4.1")
        for name in ("scenes/main.tscn", "scripts/session.gd", "scripts/enemies/enemy.gd", "scenes/enemies/melee_enemy.tscn"):
            self.assertNotIn("prototypes/", (project / name).read_text())


if __name__ == "__main__":
    unittest.main()
