"""Read-only GLB geometry/texture inventory; no Godot import or network requests."""
import argparse
import json
from pathlib import Path
import struct


def image_size(data: bytes) -> list[int] | None:
    if data.startswith(b"\x89PNG\r\n\x1a\n") and len(data) >= 24:
        return list(struct.unpack(">II", data[16:24]))
    if data.startswith(b"\xff\xd8"):
        offset = 2
        while offset + 4 <= len(data):
            if data[offset] != 0xFF:
                offset += 1
                continue
            marker = data[offset + 1]
            offset += 2
            if marker in {0x01, 0xD8, 0xD9, *range(0xD0, 0xD8)}:
                continue
            length = int.from_bytes(data[offset:offset + 2], "big")
            if length < 2 or offset + length > len(data):
                return None
            if marker in {0xC0, 0xC1, 0xC2, 0xC3, 0xC5, 0xC6, 0xC7, 0xC9, 0xCA, 0xCB, 0xCD, 0xCE, 0xCF} and length >= 7:
                height, width = struct.unpack(">HH", data[offset + 3:offset + 7])
                return [width, height]
            offset += length
    return None


def inspect(path: Path) -> dict:
    with path.open("rb") as source:
        magic, version, length = struct.unpack("<4sII", source.read(12))
        if magic != b"glTF" or version != 2 or length != path.stat().st_size:
            raise ValueError("Not a complete glTF 2.0 binary")
        chunk_length, chunk_type = struct.unpack("<II", source.read(8))
        if chunk_type != 0x4E4F534A:
            raise ValueError("Missing JSON chunk")
        document = json.loads(source.read(chunk_length))
        binary = b""
        if source.tell() < length:
            binary_length, binary_type = struct.unpack("<II", source.read(8))
            if binary_type == 0x004E4942:
                binary = source.read(binary_length)
    triangles = 0
    primitives = 0
    for mesh in document.get("meshes", []):
        for primitive in mesh.get("primitives", []):
            primitives += 1
            accessor = document["accessors"][primitive["indices"] if "indices" in primitive else primitive["attributes"]["POSITION"]]
            if primitive.get("mode", 4) == 4:
                triangles += accessor["count"] // 3
    images = []
    for image in document.get("images", []):
        info = {"name": image.get("name", ""), "mime_type": image.get("mimeType", ""), "embedded": "bufferView" in image}
        if "bufferView" in image:
            view = document["bufferViews"][image["bufferView"]]
            data = binary[view.get("byteOffset", 0):view.get("byteOffset", 0) + view["byteLength"]]
            info["bytes"] = len(data)
            dimensions = image_size(data)
            if dimensions is not None:
                info["size"] = dimensions
        images.append(info)
    return {
        "file": path.name, "bytes": length, "triangles": triangles,
        "primitives": primitives, "materials": len(document.get("materials", [])),
        "images": images, "animations": len(document.get("animations", [])),
        "skins": len(document.get("skins", [])),
        "generator": document.get("asset", {}).get("generator", ""),
        "extensions_required": document.get("extensionsRequired", []),
        "external_resources": any("uri" in item and not item["uri"].startswith("data:") for item in document.get("buffers", []) + document.get("images", []))
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("files", type=Path, nargs="+")
    args = parser.parse_args()
    for filename in args.files:
        print(json.dumps(inspect(filename)))
