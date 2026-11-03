"""Offline mapping dependency/version/vendor checks; no credentials or network."""

import hashlib
import json
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from record_cyclops_vendor import canonical


class LevelAuthoringAssetTests(unittest.TestCase):
    def test_pinned_vendor_bytes_and_explicit_patch(self):
        record = json.loads((ROOT / "docs/third-party/cyclops-1.5.2.json").read_text())
        self.assertEqual(record["version"], "1.5.2")
        self.assertEqual(record["archive_sha256"], "ea6d7a018e596d4a7c33657513622b2acd9c21b7590b764c9d62f6db7144517e")
        self.assertEqual(len(record["patched_file_sha256"]), 4)
        for path, upstream in record["upstream_file_sha256"].items():
            expected = record["patched_file_sha256"].get(path, upstream)
            self.assertEqual(hashlib.sha256(canonical(path, (ROOT / path).read_bytes())).hexdigest(), expected, path)
        self.assertTrue((ROOT / record["local_patch"]).is_file())

    def test_runtime_dependency_closure_excludes_authoring(self):
        pending = ["scenes/levels/generated/mapping_example.tscn"]
        seen = set()
        while pending:
            path = pending.pop()
            if "%s" in path:
                choices = {"scenes/models/%s.tscn": ["adept", "wall_torch", "stone_urn"], "scenes/props/%s.tscn": ["torch", "urn"]}
                self.assertIn(path, choices, "Dynamic dependency needs an explicit bounded inventory")
                pending.extend(path % choice for choice in choices[path])
                continue
            if path in seen:
                continue
            seen.add(path)
            self.assertFalse(path.startswith(("addons/", "scenes/authoring/", "tools/", "tests/", "scripts/prototypes/")), path)
            self.assertTrue((ROOT / path).is_file(), path)
            if Path(path).suffix in (".tscn", ".tres"):
                pending.extend(re.findall(r'path="res://([^\"]+)"', (ROOT / path).read_text()))
            elif Path(path).suffix == ".gd":
                text = (ROOT / path).read_text()
                pending.extend(re.findall(r'(?:preload|load)\("res://([^\"]+)"', text))
                pending.extend(re.findall(r'extends "res://([^\"]+)"', text))
                self.assertNotRegex(text, r"HTTPRequest|HTTPClient|MESHY_API_KEY")
        self.assertIn("scripts/levels/authored_level.gd", seen)
        self.assertIn("scripts/enemies/warden_presentation.gd", seen)

    def test_example_stays_editable_and_runtime_native(self):
        source = (ROOT / "scenes/authoring/mapping_example.tscn").read_text()
        built = (ROOT / "scenes/levels/generated/mapping_example.tscn").read_text()
        self.assertIn("addons/cyclops_level_builder/nodes/cyclops_block.gd", source)
        self.assertIn("scripts/levels/level_placement.gd", source)
        self.assertNotIn('path="res://addons/', built)
        self.assertIn('type="NavigationMesh"', built)
        self.assertIn('type="ConvexPolygonShape3D"', built)
        self.assertIn('type="ArrayMesh"', built)
        self.assertEqual(hashlib.sha256(source.replace("\r\n", "\n").encode()).hexdigest(), re.search(r'authoring_sha256 = "([a-f0-9]+)"', built)[1])

    def test_editor_dependencies_and_credentials_are_export_excluded(self):
        project = (ROOT / "project.godot").read_text()
        self.assertNotIn("[autoload]", project)
        self.assertIn("addons/cyclops_level_builder/plugin.cfg", project)
        self.assertIn("addons/cinderkeep_level_tools/plugin.cfg", project)
        preset = (ROOT / "export_presets.cfg").read_text()
        for exclusion in ("addons/*", "scenes/authoring/*", "tests/*", "tools/*", ".env", ".env.*"):
            self.assertIn(exclusion, preset)
        self.assertIn('config/version="0.6.0"', project)
        self.assertIn('export_path="builds/windows-0.6.0/Cinderkeep.exe"', preset)
        # Editor preview must not silently switch accepted lossless 1K maps to VRAM.
        for folder in ("environment/photographic", "models/enemy-adept", "models/enemy-warden", "models/prop-torch", "models/prop-urn", "models/warden-animated", "models/weapon-cleaver", "prototypes/warden-meshy-ab", "prototypes/warden-pilot/winner"):
            for path in (ROOT / "assets" / folder).glob("*.jpg.import"):
                settings = path.read_text()
                self.assertIn("compress/mode=0", settings, str(path))
                self.assertIn("detect_3d/compress_to=0", settings, str(path))

    def test_accepted_builds_remain_unchanged_when_present(self):
        for version, directory in (("0.4.1", "windows"), ("0.5.0", "windows-0.5.0")):
            record = json.loads((ROOT / f"docs/release/release-{version}.json").read_text())
            for entry in record["artifacts"]:
                path = ROOT / "builds" / directory / entry["name"]
                if path.exists():
                    self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), entry["sha256"])

    def test_editor_component_notices_are_preserved(self):
        base = ROOT / "addons/cyclops_level_builder"
        self.assertIn("Mark McKay", (base / "LICENSE.md").read_text(encoding="utf-8"))
        self.assertIn("Apache", (base / "art/fonts/Roboto/LICENSE.txt").read_text(encoding="utf-8"))


if __name__ == "__main__":
    unittest.main()
