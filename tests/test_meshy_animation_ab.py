"""Offline request/budget/secret-safety tests. Never reads the actual key."""

import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import Mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))
import meshy_animation_ab as ab


def record():
    return {"authorization": {"ceiling_credits": 14}, "source_sha256": ab.SOURCE_SHA256, "action_ids": [0, 21, 219], "stages": {}}


class MeshyAnimationABTests(unittest.TestCase):
    def test_only_fixed_routes_and_actions_are_accepted(self):
        for path in ["/openapi/v1/balance", "/openapi/v1/animations/library?action_ids=0,21,219", "/openapi/v1/rigging/saved-task-123"]:
            ab.validate_request(path, None)
        ab.validate_request("/openapi/v1/animations", {"rig_task_id": "saved-rig-123", "action_ids": [0, 21, 219]})
        for path, body in [("/openapi/v1/text-to-motion", {}), ("/openapi/v1/animations", {"rig_task_id": "saved-rig-123", "action_ids": [4]}), ("/openapi/v1/rigging", {"model_url": "https://unapproved.invalid/model.glb", "height_meters": 1.8}), ("/openapi/v1/balance?other=true", None)]:
            with self.assertRaises(ab.SafeError):
                ab.validate_request(path, body)

    def test_record_rejects_extra_budget_stages_or_actions(self):
        for mutate in [lambda r: r["authorization"].update(ceiling_credits=15), lambda r: r.update(action_ids=[0, 21, 4]), lambda r: r["stages"].update(extra={"reserved_credits": 3})]:
            value = record()
            mutate(value)
            with self.assertRaises(ab.SafeError):
                ab.validate_record(value)

    def test_missing_stage_without_submit_never_requests(self):
        with tempfile.TemporaryDirectory() as directory:
            request = Mock()
            with self.assertRaises(ab.SafeError):
                ab.run_stage("fake-key", record(), directory, "rig", False, request=request)
            request.assert_not_called()

    def test_ambiguous_stage_cannot_be_resubmitted(self):
        for state in ["SUBMITTING", "UNKNOWN"]:
            with tempfile.TemporaryDirectory() as directory:
                value = record()
                value["stages"]["rig"] = {"submission": state, "reserved_credits": 5}
                request = Mock()
                with self.assertRaisesRegex(ab.SafeError, "ambiguous"):
                    ab.run_stage("fake-key", value, directory, "rig", True, request=request)
                request.assert_not_called()

    def test_terminal_failure_never_retries(self):
        with tempfile.TemporaryDirectory() as directory:
            value = record()
            value["stages"]["rig"] = {"id": "saved-task-123", "status": "FAILED", "reserved_credits": 5}
            request = Mock()
            with self.assertRaises(ab.SafeError):
                ab.run_stage("fake-key", value, directory, "rig", True, request=request)
            request.assert_not_called()

    def test_submission_is_reserved_before_post_and_unknown_is_durable(self):
        with tempfile.TemporaryDirectory() as directory:
            value = record()

            def request(key, path, body=None):
                if body is None:
                    return {"balance": 100}
                saved = json.loads((Path(directory) / "record.json").read_text())
                self.assertEqual(saved["stages"]["rig"], {"submission": "SUBMITTING", "reserved_credits": 5})
                self.assertNotIn("fake-key", json.dumps(saved))
                self.assertNotIn("data:", json.dumps(saved))
                raise ab.SafeError("simulated ambiguous transport")

            with self.assertRaises(ab.SafeError):
                ab.run_stage("fake-key", value, directory, "rig", True, request=request)
            self.assertEqual(json.loads((Path(directory) / "record.json").read_text())["stages"]["rig"]["submission"], "UNKNOWN")

    def test_insufficient_balance_prevents_post(self):
        with tempfile.TemporaryDirectory() as directory:
            request = Mock(return_value={"balance": 13})
            with self.assertRaisesRegex(ab.SafeError, "Insufficient"):
                ab.run_stage("fake-key", record(), directory, "rig", True, request=request)
            self.assertEqual(request.call_count, 1)

    def test_saved_id_resumes_by_get_and_sanitizes_result(self):
        with tempfile.TemporaryDirectory() as directory:
            value = record()
            value["stages"]["rig"] = {"id": "saved-task-123", "submission": "CONFIRMED", "reserved_credits": 5}
            task = {"id": "saved-task-123", "status": "SUCCEEDED", "progress": 100, "consumed_credits": 5, "token": "secret", "result": {"rigged_character_glb_url": "https://assets.meshy.ai/result.glb?signed=secret"}}
            request = Mock(return_value=task)

            def downloader(url, path, glb=False):
                path.write_bytes(b"glTFtest")
                return {"file": path.name, "bytes": path.stat().st_size, "sha256": ab.checksum(path)}

            ab.run_stage("fake-key", value, directory, "rig", True, request=request, downloader=downloader)
            request.assert_called_once_with("fake-key", "/openapi/v1/rigging/saved-task-123")
            saved = (Path(directory) / "record.json").read_text()
            self.assertNotIn("secret", saved)
            self.assertNotIn("https://", saved)
            self.assertNotIn("fake-key", saved)
            request.reset_mock()
            ab.run_stage("fake-key", value, directory, "rig", True, request=request)
            request.assert_not_called()

    def test_missing_or_excessive_charge_blocks_download(self):
        for charge in [None, 6, -1, True]:
            with self.assertRaises(ab.SafeError):
                ab.check_charge({"consumed_credits": charge}, 5)

    def test_animation_requires_successful_rig(self):
        with tempfile.TemporaryDirectory() as directory:
            request = Mock()
            with self.assertRaises(ab.SafeError):
                ab.run_stage("fake-key", record(), directory, "animate", True, request=request)
            request.assert_not_called()

    def test_lock_prevents_parallel_trial_and_is_cleaned_up(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            with ab.trial_lock(path):
                with self.assertRaises(ab.SafeError):
                    with ab.trial_lock(path):
                        pass
            self.assertFalse((path / "trial.lock").exists())


if __name__ == "__main__":
    unittest.main()
