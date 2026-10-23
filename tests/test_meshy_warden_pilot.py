"""Offline pilot guards; no real key, paid submissions or remote requests."""

from copy import deepcopy
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import Mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import meshy_warden_pilot as pilot


class WardenPilotSafetyTests(unittest.TestCase):
    def setUp(self):
        self.plan = pilot.load_plan()
        self.record = pilot.new_record(self.plan, {"balance": 1000, "actions": []})

    def ready_candidates(self):
        for name in pilot.CANDIDATES:
            self.record["stages"][name] = {"id": "saved-" + name + "-task", "reserved_credits": 20, "status": "SUCCEEDED", "consumed_credits": 20}

    def test_fixed_plan_has_three_standard_a_pose_candidates_and_90_credit_total(self):
        self.assertEqual(sum(self.plan["costs"].values()), 90)
        self.assertEqual(self.plan["model"], "meshy-7.1")
        self.assertEqual([action["id"] for action in self.plan["actions"]], [0, 21, 219, 178, 8])
        for candidate in self.plan["candidates"]:
            self.assertLessEqual(len(candidate["prompt"]), 800)
            body = pilot.preview_body(self.plan, candidate["id"])
            self.assertEqual(body["pose_mode"], "a-pose")
            self.assertEqual(body["geometry_resolution"], "standard")
            self.assertEqual(body["target_polycount"], 8000)
            self.assertTrue(body["should_remesh"])
            pilot.validate_request(pilot.TEXT_ROUTE, body, self.plan)

    def test_ultra_other_models_and_extra_actions_are_refused(self):
        for field, value in (("geometry_resolution", "4k"), ("ai_model", "meshy-t2.5"), ("pose_mode", ""), ("prompt", "unapproved model")):
            body = pilot.preview_body(self.plan, "c01")
            body[field] = value
            with self.assertRaises(pilot.SafeError):
                pilot.validate_request(pilot.TEXT_ROUTE, body, self.plan)
        with self.assertRaises(pilot.SafeError):
            pilot.validate_request("/openapi/v1/animations", {"rig_task_id": "saved-rig-task", "action_ids": [0, 21, 219]}, self.plan)
        with self.assertRaises(pilot.SafeError):
            pilot.validate_request("/openapi/v1/remesh", {}, self.plan)

    def test_plan_hash_changes_block_resume(self):
        changed = deepcopy(self.plan)
        changed["candidates"][0]["prompt"] += " changed"
        with self.assertRaises(pilot.SafeError):
            pilot.validate_record(self.record, changed)

    def test_incorrect_reservation_or_extra_stage_is_refused(self):
        for stages in ({"c01": {"reserved_credits": 21}}, {"c04": {"reserved_credits": 20}}):
            self.record["stages"] = stages
            with self.assertRaises(pilot.SafeError):
                pilot.validate_record(self.record, self.plan)

    def test_resume_only_cannot_pay_for_missing_candidate(self):
        with tempfile.TemporaryDirectory() as directory:
            request = Mock()
            with self.assertRaises(pilot.SafeError):
                pilot.run_stage("fake-key", self.record, self.plan, directory, "c01", request=request)
            request.assert_not_called()

    def test_unknown_submissions_cannot_be_replaced(self):
        with tempfile.TemporaryDirectory() as directory:
            for state in ("SUBMITTING", "UNKNOWN"):
                self.record["stages"] = {"c01": {"reserved_credits": 20, "submission": state}}
                request = Mock()
                with self.assertRaisesRegex(pilot.SafeError, "Ambiguous"):
                    pilot.run_stage("fake-key", self.record, self.plan, directory, "c01", True, request=request)
                request.assert_not_called()

    def test_failed_stage_is_not_retried(self):
        with tempfile.TemporaryDirectory() as directory:
            self.record["stages"]["c01"] = {"reserved_credits": 20, "id": "saved-c01-task", "status": "FAILED"}
            request = Mock()
            with self.assertRaisesRegex(pilot.SafeError, "failed"):
                pilot.run_stage("fake-key", self.record, self.plan, directory, "c01", True, request=request)
            request.assert_not_called()

    def test_reservation_precedes_post_and_ambiguous_result_is_durable(self):
        with tempfile.TemporaryDirectory() as directory:
            def request(key, path, body=None):
                if body is None:
                    return {"balance": 1000}
                saved = json.loads((Path(directory) / "record.json").read_text())
                self.assertEqual(saved["stages"]["c01"], {"submission": "SUBMITTING", "reserved_credits": 20})
                self.assertNotIn("fake-key", json.dumps(saved))
                raise pilot.SafeError("simulated transport ambiguity")
            with self.assertRaises(pilot.SafeError):
                pilot.run_stage("fake-key", self.record, self.plan, directory, "c01", True, request=request)
            saved = json.loads((Path(directory) / "record.json").read_text())
            self.assertEqual(saved["stages"]["c01"]["submission"], "UNKNOWN")

    def test_insufficient_remaining_balance_prevents_post(self):
        with tempfile.TemporaryDirectory() as directory:
            request = Mock(return_value={"balance": 89})
            with self.assertRaisesRegex(pilot.SafeError, "Insufficient"):
                pilot.run_stage("fake-key", self.record, self.plan, directory, "c01", True, request=request)
            self.assertEqual(request.call_count, 1)

    def test_downstream_requires_explicit_successful_selection(self):
        with self.assertRaises(pilot.SafeError):
            pilot.request_for(self.record, self.plan, "texture")
        with self.assertRaises(pilot.SafeError):
            pilot.select_candidate(self.record, "c01")
        self.ready_candidates()
        pilot.select_candidate(self.record, "c02")
        route, body = pilot.request_for(self.record, self.plan, "texture")
        self.assertEqual(route, pilot.TEXT_ROUTE)
        self.assertEqual(body["preview_task_id"], "saved-c02-task")
        self.assertTrue(body["enable_pbr"])
        self.assertEqual(body["texture_resolution"], "2k")

    def test_selection_is_locked_after_downstream_reservation(self):
        self.ready_candidates()
        pilot.select_candidate(self.record, "c01")
        self.record["locked_selection"] = "c01"
        self.record["stages"]["texture"] = {"reserved_credits": 10}
        with self.assertRaises(pilot.SafeError):
            pilot.select_candidate(self.record, "c02")
        self.record["selected"] = "c02"
        with self.assertRaisesRegex(pilot.SafeError, "lock"):
            pilot.validate_record(self.record, self.plan)

    def test_resume_download_uses_saved_id_and_omits_signed_urls(self):
        with tempfile.TemporaryDirectory() as directory:
            self.record["stages"]["c01"] = {"id": "saved-c01-task", "reserved_credits": 20, "submission": "CONFIRMED"}
            request = Mock(return_value={"id": "saved-c01-task", "status": "SUCCEEDED", "progress": 100, "consumed_credits": 20, "model_urls": {"glb": "https://assets.meshy.ai/source.glb?signed=secret"}, "secret": "do-not-store"})
            def downloader(url, path, glb=False):
                path.write_bytes(b"glTFfixture")
                return {"file": path.name, "bytes": path.stat().st_size, "sha256": pilot.checksum(path)}
            pilot.run_stage("fake-key", self.record, self.plan, directory, "c01", True, request=request, downloader=downloader)
            request.assert_called_once_with("fake-key", pilot.TEXT_ROUTE + "/saved-c01-task")
            saved = (Path(directory) / "record.json").read_text()
            self.assertNotIn("signed=", saved)
            self.assertNotIn("secret", saved)
            self.assertNotIn("fake-key", saved)
            request.reset_mock()
            pilot.run_stage("fake-key", self.record, self.plan, directory, "c01", True, request=request)
            request.assert_not_called()


if __name__ == "__main__":
    unittest.main()
