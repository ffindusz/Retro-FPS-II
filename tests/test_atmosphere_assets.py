"""Offline source/provenance checks; no network or model-generation requests."""
from array import array
import hashlib
import json
import math
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
        replaced = json.loads((ROOT / "docs/playtest-fixes-audio.json").read_text())["sha256"]
        for relative, expected in baseline["source_hashes"].items():
            expected = replaced.get(relative, expected)
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

    def test_loops_are_loudness_matched_and_audible_on_small_speakers(self):
        levels = []
        for path in sorted((ROOT / "assets/audio/ambience").glob("*.wav")):
            with wave.open(str(path), "rb") as source:
                samples = array("h", source.readframes(source.getnframes()))
            if sys.byteorder != "little":
                samples.byteswap()
            values = [value / 32768.0 for value in samples]
            total = sum(value * value for value in values)
            levels.append(math.sqrt(total / len(values)))
            # Two cascaded one-pole low-passes at 150 Hz approximate sub-bass energy.
            coefficient = math.exp(-2.0 * math.pi * 150.0 / 22050.0)
            first = second = sub = 0.0
            for value in values:
                first = (1.0 - coefficient) * value + coefficient * first
                second = (1.0 - coefficient) * first + coefficient * second
                sub += second * second
            self.assertLess(sub / total, 0.4, f"{path.name} is mostly inaudible sub-bass")
        self.assertLess(abs(20.0 * math.log10(levels[0] / levels[1])), 1.0)
        for level in levels:
            self.assertGreater(20.0 * math.log10(level), -26.0)

    def test_replaced_enemy_cues_keep_format_level_and_timing(self):
        for name, duration in {"enemy_melee": 0.38, "enemy_charge": 0.65, "enemy_cast": 0.18}.items():
            path = ROOT / f"assets/audio/combat/{name}.wav"
            with wave.open(str(path), "rb") as source:
                self.assertEqual((source.getnchannels(), source.getsampwidth(), source.getframerate()), (1, 2, 22050))
                self.assertAlmostEqual(source.getnframes() / 22050, duration, delta=0.001)
                samples = array("h", source.readframes(source.getnframes()))
            if sys.byteorder != "little":
                samples.byteswap()
            self.assertLessEqual(max(abs(value) for value in samples), 16384, name)
            self.assertEqual((samples[0], samples[-1]), (0, 0), name)

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
