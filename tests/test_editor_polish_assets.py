"""Offline editor-polish packaging/schema checks; no Godot/API/key access."""

import hashlib
import json
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]


class EditorPolishAssetsTests(unittest.TestCase):
    def test_runtime_catalog_is_bounded_and_never_instantiates_levels(self):
        code = (ROOT / "scripts/levels/built_level_catalog.gd").read_text(encoding="utf-8")
        self.assertIn('res://scenes/levels/generated/', code)
        self.assertIn("ResourceLoader.list_directory", code)
        self.assertIn("get_state()", code)
        self.assertNotIn(".instantiate(", code)
        for forbidden in ("EditorInterface", "res://addons/", "user://", "HTTPRequest", "HTTPClient"):
            self.assertNotIn(forbidden, code)

    def test_example_has_versioned_provenance_without_changing_authored_source(self):
        source = (ROOT / "scenes/authoring/mapping_example.tscn").read_text(encoding="utf-8")
        built = (ROOT / "scenes/levels/generated/mapping_example.tscn").read_text(encoding="utf-8")
        self.assertIn("authoring_build_version = 1", built)
        self.assertRegex(built, r'authoring_dependencies_sha256 = "[0-9a-f]{64}"')
        self.assertEqual(hashlib.sha256(source.replace("\r\n", "\n").encode()).hexdigest(), re.search(r'authoring_sha256 = "([0-9a-f]+)"', built)[1])
        self.assertNotIn("PlacementGhost", source)
        self.assertNotIn('path="res://addons/', built)

    def test_export_excludes_private_test_maps_and_tools(self):
        preset = (ROOT / "export_presets.cfg").read_text()
        for pattern in ("addons/*", "scenes/authoring/*", "scenes/levels/generated/_*", "scenes/levels/generated/catalog_test_*", "scenes/levels/generated/editor_polish_test_*", "tools/*", "tests/*", ".env"):
            self.assertIn(pattern, preset)
        self.assertIn('export_path="builds/windows-0.7.0/Cinderkeep.exe"', preset)

    def test_checked_cli_preflights_before_export_and_uses_non_overwriting_copy(self):
        script = (ROOT / "tools/export_checked.ps1").read_text()
        self.assertLess(script.index("tools/check_level_exports.gd"), script.index("Invoke-Godot @($mode"))
        self.assertIn("snapshot.signature -ne $current.signature", script)
        self.assertIn("[System.IO.File]::Copy($copy.Source, $copy.Target, $false)", script)
        self.assertNotRegex(script, r"Remove-Item|git reset|--submit|MESHY_API_KEY")

    def test_stock_export_warning_does_not_claim_to_abort(self):
        code = (ROOT / "addons/cinderkeep_level_tools/export_warning.gd").read_text()
        self.assertIn("EXPORT_MESSAGE_WARNING", code)
        self.assertIn("bypasses", code)
        self.assertNotIn("queue_free", code)
        self.assertNotIn("remove_absolute", code)

    def test_previous_versioned_handoffs_remain_unchanged_when_present(self):
        for version, directory in (("0.4.1", "windows"), ("0.5.0", "windows-0.5.0"), ("0.6.0", "windows-0.6.0"), ("0.6.1", "windows-0.6.1"), ("0.6.2", "windows-0.6.2")):
            record = json.loads((ROOT / f"docs/release/release-{version}.json").read_text())
            for entry in record["artifacts"]:
                path = ROOT / "builds" / directory / entry["name"]
                if path.exists():
                    self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), entry["sha256"])


if __name__ == "__main__":
    unittest.main()
