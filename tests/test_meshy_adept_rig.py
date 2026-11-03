"""Offline request/budget/retry-safety tests for the Adept rig tool. Never reads the actual key."""

from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import Mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import meshy_adept_rig as rig


def fresh_record(plan):
    return rig.new_record(plan, {"balance": 1000})


class MeshyAdeptRigTests(unittest.TestCase):
    def setUp(self):
        self.plan = rig.load_plan()

    def test_plan_matches_authorization(self):
        self.assertEqual(self.plan["ceiling_credits"], 40)
        self.assertEqual([a["role"] for a in self.plan["actions"]], ["Idle", "Walk", "Cast", "Hit", "Death"])
        self.assertLessEqual(sum(rig.COSTS.values()), rig.CEILING)

    def test_only_fixed_routes_bodies_and_actions_are_accepted(self):
        ids = rig.action_ids(self.plan)
        for path in ["/openapi/v1/balance", rig.LIBRARY_ROUTE, rig.library_route(ids), "/openapi/v1/rigging/saved-task-123"]:
            rig.validate_request(path, None, self.plan)
        rig.validate_request("/openapi/v1/rigging", {"input_task_id": rig.REFINE_TASK, "height_meters": 2.0}, self.plan)
        rig.validate_request("/openapi/v1/animations", {"rig_task_id": "saved-rig-123", "action_ids": ids}, self.plan)
        for path, body in [
            ("/openapi/v2/text-to-3d", {"prompt": "x"}),
            ("/openapi/v1/rigging", {"input_task_id": "another-task-1234", "height_meters": 2.0}),
            ("/openapi/v1/rigging", {"input_task_id": rig.REFINE_TASK, "height_meters": 1.0}),
            ("/openapi/v1/rigging", {"model_url": "https://unapproved.invalid/model.glb", "height_meters": 2.0}),
            ("/openapi/v1/rigging", {"model_url": "data:model/gltf-binary;base64,AAAA", "height_meters": 2.0}),
            ("/openapi/v1/animations", {"rig_task_id": "saved-rig-123", "action_ids": ids[:-1] + [4]}),
            ("/openapi/v1/balance?other=true", None),
        ]:
            with self.assertRaises(rig.SafeError):
                rig.validate_request(path, body, self.plan)

    def test_paid_stage_requires_submit_and_ceiling(self):
        with tempfile.TemporaryDirectory() as directory:
            request = Mock()
            record = fresh_record(self.plan)
            with self.assertRaises(rig.SafeError):
                rig.run_stage("key", record, self.plan, directory, "rig", submit=False, request=request)
            request.assert_not_called()
            record["stages"]["rig"] = {"reserved_credits": 5, "id": "rig-task-12345", "status": "SUCCEEDED"}
            record["stages"]["animate"] = {"reserved_credits": 99}
            with self.assertRaises(rig.SafeError):
                rig.validate_record(record)

    def test_failed_or_ambiguous_stage_is_never_resubmitted(self):
        with tempfile.TemporaryDirectory() as directory:
            for stage in [{"reserved_credits": 5, "id": "rig-task-12345", "status": "FAILED"}, {"reserved_credits": 5, "submission": "UNKNOWN"}]:
                record = fresh_record(self.plan)
                record["stages"]["rig"] = stage
                request = Mock()
                with self.assertRaises(rig.SafeError):
                    rig.run_stage("key", record, self.plan, directory, "rig", submit=True, request=request)
                request.assert_not_called()

    def test_rejected_refine_rig_allows_exactly_one_upload_fallback(self):
        with tempfile.TemporaryDirectory() as directory:
            record = fresh_record(self.plan)
            record["stages"]["rig"] = {"submission": "REJECTED", "reserved_credits": 5, "route": "refine_task"}
            with self.assertRaises(rig.SafeError):
                rig.run_stage("key", record, self.plan, directory, "rig", submit=True, upload=False, request=Mock())
            posts = []

            def request(key, path, body=None, plan=None):
                if body is not None:
                    posts.append(path)
                    raise rig.SafeError("Meshy HTTP 400; response suppressed.")
                return {"balance": 1000}

            with self.assertRaises(rig.SafeError):
                rig.run_stage("key", record, self.plan, directory, "rig", submit=True, upload=True, request=request)
            self.assertEqual(len(record["rejected_attempts"]), 1)
            with self.assertRaises(rig.SafeError):
                rig.run_stage("key", record, self.plan, directory, "rig", submit=True, upload=True, request=request)
            self.assertEqual(posts, ["/openapi/v1/rigging"])

    def test_animation_waits_for_successful_rig(self):
        with tempfile.TemporaryDirectory() as directory:
            record = fresh_record(self.plan)
            request = Mock(return_value={"balance": 1000})
            with self.assertRaises(rig.SafeError):
                rig.run_stage("key", record, self.plan, directory, "animate", submit=True, request=request)
            request.assert_not_called()

    def test_record_never_contains_upload_data_or_key(self):
        with tempfile.TemporaryDirectory() as directory:
            record = fresh_record(self.plan)
            calls = []

            def request(key, path, body=None, plan=None):
                calls.append((path, body))
                if path == "/openapi/v1/balance":
                    return {"balance": 1000}
                if body is not None:
                    return {"result": "rig-task-12345"}
                return {"id": "rig-task-12345", "status": "FAILED", "progress": 0}

            with self.assertRaises(rig.SafeError):
                rig.run_stage("secret-key", record, self.plan, directory, "rig", submit=True, upload=True, request=request, wait=lambda s: None)
            text = (Path(directory) / "record.json").read_text(encoding="utf-8")
            self.assertNotIn("secret-key", text)
            self.assertNotIn("base64", text)
            self.assertEqual(sum(1 for path, body in calls if body is not None), 1)


if __name__ == "__main__":
    unittest.main()
