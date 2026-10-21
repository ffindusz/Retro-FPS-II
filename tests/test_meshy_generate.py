"""Offline authoring-tool checks. No Meshy requests or generation credits used."""
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("meshy_generate", ROOT / "tools/meshy_generate.py")
meshy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(meshy)


class MeshyAuthoringTests(unittest.TestCase):
    def test_six_original_prompts_fit_api_limits_and_budgets(self):
        plan = json.loads((ROOT / "docs/meshy-models.json").read_text())
        self.assertEqual(len(plan["assets"]), 6)
        self.assertEqual(len({asset["id"] for asset in plan["assets"]}), 6)
        self.assertEqual(6 * (plan["estimated_preview_credits"] + plan["estimated_refine_credits"]), 90)
        for asset in plan["assets"]:
            self.assertLessEqual(len(asset["prompt"]), 800)
            self.assertLessEqual(len(asset["texture_prompt"]), 800)
            self.assertLessEqual(asset["target_polycount"], 10000 if asset["id"].startswith("enemy-") else 5000)

    def test_snapshot_omits_signed_urls_and_unknown_fields(self):
        value = meshy.snapshot({"id": "job", "status": "SUCCEEDED", "consumed_credits": 5,
                                "model_urls": {"glb": "signed"}, "token": "secret"})
        self.assertEqual(value, {"id": "job", "status": "SUCCEEDED", "consumed_credits": 5})

    def test_dotenv_quotes_and_comments_without_accessing_real_key(self):
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory)
            for assignment in ['MESHY_API_KEY="fake-key"', "export MESHY_API_KEY='fake-key'", "MESHY_API_KEY=fake-key # local"]:
                (project / ".env").write_text(assignment)
                with patch.object(meshy, "PROJECT", project), patch.dict(meshy.os.environ, {}, clear=True):
                    self.assertEqual(meshy.read_key(), "fake-key")

    def test_missing_and_ambiguous_submissions_cannot_create_paid_tasks(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory)
            asset = {"id": "weapon-cleaver"}
            plan = {"model": "meshy-t2.5", "model_type": "smart-topology"}
            with patch.object(meshy, "api_request") as request:
                with self.assertRaises(meshy.SafeError):
                    meshy.run_asset("fake", plan, asset, output, "preview", False)
                request.assert_not_called()
                meshy.save_record(output / asset["id"] / "record.json", {"preview": {"submission": "UNKNOWN"}})
                with self.assertRaises(meshy.SafeError):
                    meshy.run_asset("fake", plan, asset, output, "preview", True)
                request.assert_not_called()

    def test_unsafe_download_hosts_rejected_before_network_access(self):
        for url in ["http://assets.meshy.ai/model.glb", "https://attacker.invalid/model.glb", "https://user@assets.meshy.ai/model.glb"]:
            with self.assertRaises(meshy.SafeError):
                meshy.download(url, Path("unused.glb"))


if __name__ == "__main__":
    unittest.main()
