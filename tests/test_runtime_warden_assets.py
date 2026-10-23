"""Offline adoption checks; never read credentials or call an authoring service."""

import hashlib
import json
from pathlib import Path
import re
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from warden_rig_geometry import read_glb


class RuntimeWardenAssetTests(unittest.TestCase):
    def test_promoted_bytes_and_original_pilot_are_unchanged(self):
        target = ROOT / "assets/models/warden-animated"
        pilot = ROOT / "assets/prototypes/warden-pilot/winner"
        record = json.loads((target / "provenance.json").read_text())
        for name in ("texture", "animate"):
            data = (target / (name + ".glb")).read_bytes()
            self.assertEqual(data, (pilot / (name + ".glb")).read_bytes())
            self.assertEqual(hashlib.sha256(data).hexdigest(), record["stages"][name]["download"]["sha256"])
        self.assertFalse(json.loads((pilot / "provenance.json").read_text())["gameplay_integration"])
        self.assertTrue(record["gameplay_integration"])
        self.assertTrue(record["runtime_adoption"]["melee_only"])
        self.assertEqual(record["runtime_adoption"]["extra_meshy_credits"], 0)

    def test_runtime_resource_closure_has_no_prototype_or_authoring_dependency(self):
        pending = ["scenes/enemies/melee_enemy.tscn", "scenes/enemies/ranged_enemy.tscn"]
        seen = set()
        while pending:
            path = pending.pop()
            if path in seen:
                continue
            seen.add(path)
            self.assertNotIn("prototypes/", path)
            self.assertFalse(path.startswith(("tools/", "tests/", "docs/")))
            self.assertTrue((ROOT / path).is_file(), path)
            if Path(path).suffix in (".gd", ".tscn", ".tres"):
                text = (ROOT / path).read_text()
                self.assertNotRegex(text, r"HTTPRequest|HTTPClient|MESHY_API_KEY|\.env")
                pending.extend(re.findall(r'res://([^\s"\)]+)', text))
        for required in ("assets/models/warden-animated/animate.glb", "assets/models/warden-animated/texture.glb", "scenes/models/iron_blade.tscn", "scenes/models/adept.tscn"):
            self.assertIn(required, seen)

    def test_raw_runtime_glbs_remain_self_contained(self):
        for name in ("animate", "texture"):
            doc, _ = read_glb(ROOT / f"assets/models/warden-animated/{name}.glb")
            for entry in doc.get("images", []) + doc.get("buffers", []):
                self.assertNotIn("uri", entry)

    def test_all_new_texture_imports_keep_1k_limit_and_mipmaps(self):
        imports = list((ROOT / "assets/models/warden-animated").glob("*.jpg.import"))
        self.assertEqual(len(imports), 4)
        for path in imports:
            text = path.read_text()
            self.assertIn("process/size_limit=1024", text)
            self.assertIn("mipmaps/generate=true", text)

    def test_versioned_export_preserves_frozen_baseline_and_exclusions(self):
        self.assertIn('config/version="0.5.0"', (ROOT / "project.godot").read_text())
        preset = (ROOT / "export_presets.cfg").read_text()
        self.assertIn('export_path="builds/windows-0.5.0/Cinderkeep.exe"', preset)
        for prefix in ("assets/prototypes/*", "scenes/prototypes/*", "scripts/prototypes/*", "tools/*", "tests/*", "docs/*", ".env", ".env.*"):
            self.assertIn(prefix, preset)
        record = json.loads((ROOT / "docs/release/release-0.4.1.json").read_text())
        for entry in record["artifacts"]:
            path = ROOT / "builds/windows" / entry["name"]
            if path.exists():  # Generated builds are absent from a fresh checkout.
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), entry["sha256"])
        bundle = ROOT / "builds/releases/Cinderkeep-0.4.1-windows-x64.zip"
        if bundle.exists():
            self.assertEqual(hashlib.sha256(bundle.read_bytes()).hexdigest(), "e60788ce5615026cc8fb8df7530e9556ae349b638da87db66cf8ed0477d1b815")

    def test_shared_grip_and_cost_exception_are_explicit(self):
        record = json.loads((ROOT / "assets/models/warden-animated/provenance.json").read_text())
        adopted = record["runtime_adoption"]
        self.assertEqual(adopted["maximum_body_and_blade_triangles"], 11376)
        for path in ("scripts/enemies/warden_presentation.gd", "scripts/prototypes/warden_pilot_preview.gd"):
            self.assertIn('preload("res://scripts/enemies/warden_grip.gd")', (ROOT / path).read_text())
        self.assertEqual(adopted["native_strike_reference_seconds"], 0.6)
        self.assertEqual(adopted["authoritative_windup_seconds_unchanged"], 0.55)


if __name__ == "__main__":
    unittest.main()
