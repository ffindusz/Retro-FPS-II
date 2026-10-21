import importlib.util
import json
from pathlib import Path
import struct
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent
spec = importlib.util.spec_from_file_location("inspect_glb", ROOT / "tools/inspect_glb.py")
inspector = importlib.util.module_from_spec(spec)
spec.loader.exec_module(inspector)


class GlbInspectionTests(unittest.TestCase):
    def test_jpeg_size_without_decoding_or_third_party_libraries(self):
        jpeg = b"\xff\xd8\xff\xc0\x00\x0b\x08\x08\x00\x04\x00\x01\x01\x11\x00"
        self.assertEqual(inspector.image_size(jpeg), [1024, 2048])
        self.assertIsNone(inspector.image_size(b"not an image"))

    def test_geometry_and_embedded_texture_inventory(self):
        image = b"\x89PNG\r\n\x1a\n" + b"\0" * 8 + struct.pack(">II", 2048, 1024)
        document = {
            "asset": {"version": "2.0", "generator": "test"},
            "accessors": [{"count": 9}],
            "meshes": [{"primitives": [{"indices": 0}]}],
            "bufferViews": [{"byteOffset": 0, "byteLength": len(image)}],
            "buffers": [{"byteLength": len(image)}],
            "images": [{"bufferView": 0, "mimeType": "image/png"}]
        }
        encoded = json.dumps(document).encode()
        encoded += b" " * (-len(encoded) % 4)
        content = struct.pack("<4sII", b"glTF", 2, 12 + 8 + len(encoded) + 8 + len(image))
        content += struct.pack("<II", len(encoded), 0x4E4F534A) + encoded
        content += struct.pack("<II", len(image), 0x004E4942) + image
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "test.glb"
            path.write_bytes(content)
            report = inspector.inspect(path)
        self.assertEqual(report["triangles"], 3)
        self.assertEqual(report["images"][0]["size"], [2048, 1024])
        self.assertFalse(report["external_resources"])

    def test_incomplete_glb_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "broken.glb"
            path.write_bytes(struct.pack("<4sII", b"glTF", 2, 999))
            with self.assertRaises(ValueError):
                inspector.inspect(path)


if __name__ == "__main__":
    unittest.main()
