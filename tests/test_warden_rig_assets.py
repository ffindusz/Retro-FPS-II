import hashlib
import json
import math
from pathlib import Path
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from warden_rig_geometry import BONES, SOURCE_SHA256, accessor_values, components, guard_generated_outputs, identify_regions, read_glb, source_mesh, vertex_weights


class WardenRigAssetsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.path = ROOT / "assets/prototypes/warden-rig/warden_rig.glb"
        cls.document, cls.binary = read_glb(cls.path)
        cls.primitive = cls.document["meshes"][0]["primitives"][0]
        cls.attributes = cls.primitive["attributes"]
        cls.positions = cls.values(cls.attributes["POSITION"])
        cls.weights = cls.values(cls.attributes["WEIGHTS_0"])
        cls.joints = cls.values(cls.attributes["JOINTS_0"])
        cls.skin = cls.document["skins"][0]
        cls.names = [cls.document["nodes"][index]["name"] for index in cls.skin["joints"]]
        cls.source_points, cls.source_faces = source_mesh(ROOT / "assets/models/enemy-warden/model.glb")

    @classmethod
    def values(cls, index):
        return accessor_values(cls.document, cls.binary, index)

    def test_original_source_and_derived_provenance(self):
        record = json.loads((self.path.parent / "provenance.json").read_text())
        self.assertEqual(record["source_sha256"], SOURCE_SHA256)
        self.assertEqual(hashlib.sha256(self.path.read_bytes()).hexdigest(), record["glb_sha256"])
        self.assertEqual(hashlib.sha256((ROOT / record["authoring_script"]).read_bytes()).hexdigest(), record["authoring_script_sha256"])
        self.assertEqual(hashlib.sha256((ROOT / "tools/warden_rig_geometry.py").read_bytes()).hexdigest(), record["weight_helper_sha256"])
        self.assertFalse(record["gameplay_integration"])

    def test_mesh_regions_are_disconnected_without_geometry_cuts(self):
        groups = components(self.source_points, self.source_faces)
        weapon, hand = identify_regions(self.source_points, groups)
        self.assertEqual([len(group) for group in groups], [6821, 326, 180])
        self.assertEqual((len(weapon), len(hand)), (180, 326))
        self.assertTrue(weapon.isdisjoint(hand))

    def test_real_skin_and_complete_finite_bind_matrices(self):
        self.assertEqual(len(self.document["skins"]), 1)
        self.assertEqual(set(self.names), set(BONES))
        matrices = self.values(self.skin["inverseBindMatrices"])
        self.assertEqual(len(matrices), 21)
        self.assertTrue(all(len(matrix) == 16 and all(math.isfinite(value) for value in matrix) for matrix in matrices))
        self.assertTrue(any(node.get("skin") == 0 and "mesh" in node for node in self.document["nodes"]))

    def test_all_exported_weights_are_finite_normalized_and_bounded(self):
        self.assertEqual(len(self.weights), len(self.positions))
        for joints, weights in zip(self.joints, self.weights):
            self.assertEqual(len(weights), 4)
            self.assertAlmostEqual(sum(weights), 1.0, places=5)
            self.assertTrue(all(math.isfinite(weight) and 0 <= weight <= 1 for weight in weights))
            self.assertTrue(all(0 <= joint < 21 for joint in joints))
            self.assertLessEqual(sum(weight > 0 for weight in weights), 4)

    def test_blade_has_one_rigid_hand_child_influence(self):
        weapon_slot = self.names.index("Weapon.R")
        blade = []
        hand = []
        for index, (joints, weights) in enumerate(zip(self.joints, self.weights)):
            active = [(joint, weight) for joint, weight in zip(joints, weights) if weight > 0]
            if active == [(weapon_slot, 1.0)]:
                blade.append(index)
            if active == [(self.names.index("Hand.R"), 1.0)]:
                hand.append(index)
        self.assertEqual(len(blade), 180)
        self.assertGreaterEqual(len(hand), 326)
        parent = self.document["nodes"][self.skin["joints"][self.names.index("Hand.R")]]
        self.assertIn(self.skin["joints"][weapon_slot], parent["children"])

    def test_geometry_uv_inventory_and_normalization_preserved(self):
        self.assertEqual(len(self.positions), 7327)
        self.assertEqual(len(self.values(self.primitive["indices"])), 8462 * 3)
        expected = sorted((x, z, -y) for x, y, z in self.source_points)
        for left, right in zip(expected, sorted(self.positions)):
            self.assertLess(max(abs(a - b) for a, b in zip(left, right)), 0.000003)
        source_document, source_binary = read_glb(ROOT / "assets/models/enemy-warden/model.glb")
        source_uv = source_document["meshes"][0]["primitives"][0]["attributes"]["TEXCOORD_0"]
        original_uv = sorted(accessor_values(source_document, source_binary, source_uv))
        for left, right in zip(original_uv, sorted(self.values(self.attributes["TEXCOORD_0"]))):
            self.assertLess(max(abs(a - b) for a, b in zip(left, right)), 0.000003)

    def test_derivative_reuses_material_without_new_images_or_remote_resources(self):
        self.assertFalse(self.document.get("images"))
        self.assertFalse(self.document.get("materials"))
        self.assertFalse(any("uri" in buffer for buffer in self.document["buffers"]))

    def test_three_finite_bone_clips_with_expected_lengths(self):
        expected = {"Idle": 2.0, "Walk": 1.0, "Attack": 1.4}
        self.assertEqual({a["name"] for a in self.document["animations"]}, set(expected))
        for animation in self.document["animations"]:
            self.assertGreaterEqual(len(animation["channels"]), 21)
            for sampler in animation["samplers"]:
                times = self.values(sampler["input"])
                self.assertAlmostEqual(times[0][0], 0.0)
                self.assertAlmostEqual(times[-1][0], expected[animation["name"]], places=5)
                self.assertTrue(all(math.isfinite(value) for sample in self.values(sampler["output"]) for value in sample))

    def test_idle_walk_loop_endpoints_and_root_are_stationary(self):
        for animation in self.document["animations"]:
            for channel in animation["channels"]:
                sampler = animation["samplers"][channel["sampler"]]
                values = self.values(sampler["output"])
                name = self.document["nodes"][channel["target"]["node"]]["name"]
                if animation["name"] in ("Idle", "Walk"):
                    self.assertLess(max(abs(a - b) for a, b in zip(values[0], values[-1])), 0.00001)
                if name == "Root":
                    self.assertTrue(all(max(abs(a - b) for a, b in zip(values[0], value)) < 0.00001 for value in values))

    def test_walk_and_attack_have_real_independent_limb_rotation(self):
        for clip, bone in (("Walk", "Thigh.R"), ("Walk", "Thigh.L"), ("Attack", "UpperArm.R"), ("Attack", "Forearm.R")):
            animation = next(a for a in self.document["animations"] if a["name"] == clip)
            channel = next(c for c in animation["channels"] if c["target"]["path"] == "rotation" and self.document["nodes"][c["target"]["node"]]["name"] == bone)
            values = self.values(animation["samplers"][channel["sampler"]]["output"])
            self.assertGreater(max(sum((a - b) ** 2 for a, b in zip(values[0], value)) ** 0.5 for value in values), 0.05)

    def test_weight_helpers_are_deterministic_and_keep_regions_rigid(self):
        for point in self.source_points:
            weights = vertex_weights(point)
            self.assertEqual(weights, vertex_weights(point))
            self.assertAlmostEqual(sum(weights.values()), 1.0)
            self.assertLessEqual(len(weights), 2)
            self.assertTrue(set(weights).issubset(BONES))
        self.assertEqual(vertex_weights((0.3, -0.05, 0.4), "weapon"), {"Weapon.R": 1.0})
        self.assertEqual(vertex_weights((0.27, -0.08, 0.8), "hand"), {"Hand.R": 1.0})

    def test_coincident_uv_normal_seam_vertices_share_weights(self):
        seen = {}
        for point, joints, weights in zip(self.positions, self.joints, self.weights):
            key = tuple(round(value, 5) for value in point)
            influences = {self.names[joint]: value for joint, value in zip(joints, weights) if value > 0}
            if key in seen:
                self.assertEqual(seen[key], influences)
            else:
                seen[key] = influences

    def test_prototype_is_excluded_and_accepted_artifacts_are_unchanged(self):
        preset = (ROOT / "export_presets.cfg").read_text()
        for prefix in ("assets", "scenes", "scripts"):
            self.assertIn(prefix + "/prototypes/*", preset)
        for path in ("scripts/enemies/enemy.gd", "scenes/enemies/melee_enemy.tscn", "scripts/session.gd", "scenes/main.tscn"):
            self.assertNotIn("prototypes/", (ROOT / path).read_text())
        record = json.loads((ROOT / "docs/release/release-0.4.1.json").read_text())
        for artifact in record["artifacts"]:
            path = ROOT / "builds/windows" / artifact["name"]
            if path.exists():
                self.assertEqual(hashlib.sha256(path.read_bytes()).hexdigest(), artifact["sha256"])
        bundle = ROOT / "builds/releases/Cinderkeep-0.4.1-windows-x64.zip"
        if bundle.exists():
            self.assertEqual(hashlib.sha256(bundle.read_bytes()).hexdigest(), "e60788ce5615026cc8fb8df7530e9556ae349b638da87db66cf8ed0477d1b815")

    def test_rebuild_guard_supports_fresh_checkout_without_ignored_blend(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            glb, blend, record = root / "rig.glb", root / "rig.blend", root / "record.json"
            glb.write_bytes(b"generated")
            record.write_text(json.dumps({"glb_sha256": hashlib.sha256(b"generated").hexdigest(), "blend_sha256": "absent"}))
            guard_generated_outputs(glb, blend, record, True)
            with self.assertRaises(FileExistsError):
                guard_generated_outputs(glb, blend, record, False)

    def test_rebuild_guard_preserves_modified_generated_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            glb, blend, record = root / "rig.glb", root / "rig.blend", root / "record.json"
            glb.write_bytes(b"generated")
            blend.write_bytes(b"user edits")
            record.write_text(json.dumps({"glb_sha256": hashlib.sha256(b"generated").hexdigest(), "blend_sha256": "previous generated hash"}))
            with self.assertRaisesRegex(ValueError, "preserving user work"):
                guard_generated_outputs(glb, blend, record, True)
            self.assertEqual(blend.read_bytes(), b"user edits")


if __name__ == "__main__":
    unittest.main()
