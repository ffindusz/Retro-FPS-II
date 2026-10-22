"""Offline source/provenance checks; no network or model-generation requests."""
from array import array
import hashlib
import json
from pathlib import Path
import struct
import sys
import unittest
import wave

ROOT = Path(__file__).resolve().parent.parent


class AtmosphereAssetTests(unittest.TestCase):
    def test_accepted_sources_and_navigation_are_unchanged(self):
        baseline = json.loads((ROOT / "docs/fortress-atmosphere-baseline.json").read_text())
        self.assertEqual(len(baseline["source_hashes"]), 18)
        for relative, expected in baseline["source_hashes"].items():
            data = (ROOT / relative).read_bytes()
            # Git can check out text resources with CRLF on Windows.
            if relative.endswith(".tres"):
                data = data.replace(b"\r\n", b"\n")
            self.assertEqual(hashlib.sha256(data).hexdigest(), expected, relative)

    def test_original_environment_texture_budget_and_imports(self):
        images = sorted((ROOT / "assets/environment").glob("*.png"))
        self.assertEqual(len(images), 6)
        for path in images:
            data = path.read_bytes()
            self.assertEqual(data[:8], b"\x89PNG\r\n\x1a\n")
            self.assertEqual(struct.unpack(">II", data[16:24]), (512, 512))
            self.assertIn("mipmaps/generate=true", path.with_suffix(".png.import").read_text())

    def test_bounded_original_loops_and_no_boundary_discontinuity(self):
        loops = sorted((ROOT / "assets/audio/ambience").glob("*.wav"))
        self.assertEqual(len(loops), 2)
        hashes = set()
        for path in loops:
            with wave.open(str(path), "rb") as source:
                self.assertEqual((source.getnchannels(), source.getsampwidth(), source.getframerate(), source.getnframes()), (1, 2, 22050, 441000))
                samples = array("h", source.readframes(source.getnframes()))
            if sys.byteorder != "little":
                samples.byteswap()
            self.assertLessEqual(max(abs(value) for value in samples), 8192)
            self.assertGreater(max(samples) - min(samples), 100)
            maximum_step = max(abs(right - left) for left, right in zip(samples, samples[1:]))
            self.assertLessEqual(abs(samples[-1] - samples[0]), maximum_step)
            options = path.with_suffix(".wav.import").read_text()
            self.assertIn("compress/mode=0", options)
            self.assertIn("edit/loop_mode=2", options)
            self.assertIn("edit/normalize=false", options)
            hashes.add(hashlib.sha256(path.read_bytes()).hexdigest())
        self.assertEqual(len(hashes), 2)

    def test_photographic_maps_match_cc0_provenance_and_imports(self):
        directory = ROOT / "assets/environment/photographic"
        manifest = json.loads((directory / "provenance.json").read_text())
        self.assertEqual(manifest["license"], "CC0-1.0")
        files = set()
        for asset in manifest["assets"]:
            self.assertTrue(asset["source_url"].startswith("https://polyhaven.com/a/"))
            self.assertTrue(asset["author"])
            self.assertEqual(set(asset["maps"]), {"albedo", "normal", "roughness"})
            for kind, record in asset["maps"].items():
                path = directory / record["file"]
                data = path.read_bytes()
                self.assertEqual(hashlib.sha256(data).hexdigest(), record["sha256"], path.name)
                self.assertEqual(hashlib.md5(data).hexdigest(), record["md5"], path.name)
                options = path.with_suffix(".jpg.import").read_text()
                self.assertIn("mipmaps/generate=true", options)
                self.assertIn("process/size_limit=1024", options)
                if kind == "normal":
                    self.assertIn("compress/normal_map=1", options)
                    self.assertIn("process/normal_map_invert_y=false", options)
                files.add(path.name)
        self.assertEqual(len(files), 6)
        self.assertEqual(files, {path.name for path in directory.glob("*.jpg")})

    def test_original_sky_matches_provenance_and_panorama_budget(self):
        directory = ROOT / "assets/environment/sky"
        manifest = json.loads((directory / "provenance.json").read_text())
        path = directory / manifest["file"]
        data = path.read_bytes()
        self.assertEqual(hashlib.sha256(data).hexdigest(), manifest["sha256"])
        self.assertEqual(data[:8], b"\x89PNG\r\n\x1a\n")
        self.assertEqual(struct.unpack(">II", data[16:24]), (1024, 512))
        self.assertEqual(len(list(directory.glob("*.png"))), 1)
        options = path.with_suffix(".png.import").read_text()
        self.assertIn("mipmaps/generate=true", options)
        self.assertIn("process/size_limit=1024", options)


if __name__ == "__main__":
    unittest.main()
