import hashlib
import json
import math
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from meshy_warden_pilot import COSTS, load_plan, plan_hash
from prepare_warden_pilot import uv_triangles
from warden_rig_geometry import accessor_values, read_glb


class WardenPilotAssetsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.folder = ROOT / "assets/prototypes/warden-pilot/winner"
        cls.record = json.loads((cls.folder / "provenance.json").read_text())
        cls.document, cls.binary = read_glb(cls.folder / "animate.glb")

    def test_exact_costs_selection_and_checkpointed_files(self):
        self.assertEqual(self.record["total_credits"], 90)
        self.assertEqual(self.record["selected"], "c02")
        self.assertEqual(self.record["balance_before"] - self.record["balance_milestones"]["finish"], 90)
        self.assertEqual(self.record["plan_sha256"], plan_hash(load_plan()))
        self.assertEqual({name: stage["consumed_credits"] for name, stage in self.record["stages"].items()}, COSTS)
        for name in ("texture", "animate"):
            asset = self.record["stages"][name]["download"]
            self.assertEqual(hashlib.sha256((self.folder / asset["file"]).read_bytes()).hexdigest(), asset["sha256"])

    def test_actual_five_clips_and_humanoid_hand(self):
        self.assertEqual({a["name"] for a in self.document["animations"]}, {"Idle", "Walk_Fight_Forward", "Right_Hand_Sword_Slash", "Hit_Reaction", "Dead"})
        self.assertEqual(self.record["clip_roles"], ["Idle", "Walk", "Attack", "Hit", "Death"])
        self.assertEqual(len(self.document["skins"][0]["joints"]), 24)
        names = [self.document["nodes"][node]["name"] for node in self.document["skins"][0]["joints"]]
        self.assertIn("RightHand", names)
        self.assertNotIn("Weapon.R", names)

    def test_full_pbr_uv_triangles_and_albedo_match(self):
        self.assertEqual(uv_triangles(self.folder / "texture.glb"), uv_triangles(self.folder / "animate.glb"))
        self.assertTrue(set(self.record["animated_inventory"]["image_sha256"]) <= set(self.record["textured_inventory"]["image_sha256"]))
        self.assertTrue(self.record["pbr_atlas_triangle_uv_match"])
        self.assertEqual(self.record["textured_inventory"]["triangles"], 8290)
        self.assertEqual(self.record["animated_inventory"]["triangles"], 8290)

    def test_all_pilot_weights_are_finite_normalized(self):
        primitive = self.document["meshes"][0]["primitives"][0]
        weights = accessor_values(self.document, self.binary, primitive["attributes"]["WEIGHTS_0"])
        joints = accessor_values(self.document, self.binary, primitive["attributes"]["JOINTS_0"])
        for values, bones in zip(weights, joints):
            self.assertAlmostEqual(sum(values), 1.0, places=4)
            self.assertTrue(all(math.isfinite(value) and 0 <= value <= 1 for value in values))
            self.assertTrue(all(0 <= bone < 24 for bone in bones))

    def test_every_extracted_texture_has_1k_cap(self):
        imports = list(self.folder.glob("*.jpg.import"))
        self.assertEqual(len(imports), 4)
        for path in imports:
            self.assertIn("process/size_limit=1024", path.read_text())
            self.assertIn("mipmaps/generate=true", path.read_text())

    def test_existing_blade_is_reused_without_source_changes(self):
        blade = self.record["weapon"]
        self.assertEqual(blade["scene"], "scenes/models/iron_blade.tscn")
        self.assertEqual(hashlib.sha256((ROOT / blade["source"]).read_bytes()).hexdigest(), blade["source_sha256"])
        primitive = self.document["meshes"][0]["primitives"][0]
        count = len(accessor_values(self.document, self.binary, primitive["indices"])) // 3
        self.assertEqual(count, 8290)
        # Separate accepted blade adds 3,086 source triangles; this is a prototype
        # budget observation, not a silent production budget increase.
        self.assertEqual(count + 3086, 11376)

    def test_no_secrets_or_gameplay_integration_in_provenance(self):
        text = json.dumps(self.record)
        for forbidden in ("Bearer ", "MESHY_API_KEY", "data:model/", "Expires=", "Signature="):
            self.assertNotIn(forbidden, text)
        self.assertFalse(self.record["gameplay_integration"])
        self.assertIn("assets/prototypes/*", (ROOT / "export_presets.cfg").read_text())
        self.assertEqual(json.loads((ROOT / "docs/release/release-0.4.1.json").read_text())["version"], "0.4.1")


if __name__ == "__main__":
    unittest.main()
