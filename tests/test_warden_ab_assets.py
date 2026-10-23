import hashlib
import json
import math
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from analyze_meshy_ab import analyze
from prepare_meshy_ab import inventory
from warden_rig_geometry import accessor_values, read_glb


class WardenABAssetsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.folder = ROOT / "assets/prototypes/warden-meshy-ab"
        cls.record = json.loads((cls.folder / "provenance.json").read_text())

    def test_completed_fixed_trial_cost_and_hashes(self):
        self.assertEqual(self.record["action_ids"], [0, 21, 219])
        self.assertEqual(self.record["costs"], {"rig": 5, "animation": 9, "total": 14})
        self.assertEqual(self.record["balance_before"] - self.record["balance_after"], 14)
        self.assertFalse(self.record["authorization"]["paid_retries"])
        self.assertEqual(hashlib.sha256((self.folder / "animations.glb").read_bytes()).hexdigest(), self.record["animation_download"]["sha256"])
        self.assertEqual(hashlib.sha256((ROOT / self.record["source"]).read_bytes()).hexdigest(), self.record["source_sha256"])
        self.assertEqual(hashlib.sha256((ROOT / "assets/prototypes/warden-rig/warden_rig.glb").read_bytes()).hexdigest(), self.record["local_rig_sha256"])

    def test_actual_three_clips_and_24_bone_skin(self):
        result, uv = inventory(self.folder / "animations.glb")
        self.assertEqual(result["bones"], 24)
        self.assertEqual(result["vertices"], 7327)
        self.assertEqual(result["triangles"], 8462)
        self.assertEqual(set(result["clips"]), {"Idle", "Walk_Fight_Forward", "Right_Hand_Sword_Slash"})
        self.assertEqual([round(value, 5) for value in self.record["native_durations"]], [4.0, 1.66667, 1.5])

    def test_uv_and_albedo_compatibility_for_shared_material(self):
        from collections import Counter
        original, source_uv = inventory(ROOT / self.record["source"])
        result, output_uv = inventory(self.folder / "animations.glb")
        self.assertEqual(Counter(tuple(round(v, 5) for v in uv) for uv in source_uv), Counter(tuple(round(v, 5) for v in uv) for uv in output_uv))
        self.assertTrue(set(result["image_sha256"]) <= set(original["image_sha256"]))
        self.assertTrue(self.record["use_original_material"])
        self.assertIn("process/size_limit=1024", (self.folder / "animations_Material_0_baseColor.jpg.import").read_text())

    def test_all_meshy_skin_weights_are_finite_normalized_and_valid(self):
        document, binary = read_glb(self.folder / "animations.glb")
        attributes = document["meshes"][0]["primitives"][0]["attributes"]
        weights = accessor_values(document, binary, attributes["WEIGHTS_0"])
        joints = accessor_values(document, binary, attributes["JOINTS_0"])
        for values, bones in zip(weights, joints):
            self.assertAlmostEqual(sum(values), 1.0, places=4)
            self.assertTrue(all(math.isfinite(value) and 0 <= value <= 1 for value in values))
            self.assertTrue(all(0 <= bone < 24 for bone in bones))

    def test_blade_weight_observation_is_not_silently_repaired(self):
        report = analyze()
        self.assertEqual(report["local"]["blade"]["single_shared_rigid_bone"], "Weapon.R")
        self.assertEqual(report["local"]["blade"]["leg_or_hip_weighted_blade_vertices"], 0)
        self.assertEqual(report["meshy"]["blade"]["uv_matched_blade_vertices"], 180)
        self.assertEqual(report["meshy"]["blade"]["leg_or_hip_weighted_blade_vertices"], 180)
        self.assertIsNone(report["meshy"]["blade"]["single_shared_rigid_bone"])

    def test_records_and_prototype_runtime_do_not_include_credentials(self):
        serialized = json.dumps(self.record)
        for forbidden in ("Bearer ", "MESHY_API_KEY", "data:model/", "Expires=", "Signature="):
            self.assertNotIn(forbidden, serialized)
        self.assertFalse(self.record["gameplay_integration"])
        for name in ("warden_animation_ab.gd", "animation_ab_actor.gd", "animation_ab_clock.gd"):
            code = (ROOT / "scripts/prototypes" / name).read_text()
            self.assertNotIn("api.meshy.ai", code)
            self.assertNotIn('".env"', code)
        self.assertIn("assets/prototypes/*", (ROOT / "export_presets.cfg").read_text())


if __name__ == "__main__":
    unittest.main()
