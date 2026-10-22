# Photographic fortress stone

Six unchanged 1024px JPEG maps were downloaded on 2026-10-22 from Poly Haven's official file API and verified against its MD5 values. Local SHA-256, exact download URLs and source metadata are in [provenance.json](provenance.json).

| Use | Asset / author | Maps | Tile size |
|---|---|---|---|
| Walls and trim | [Medieval Blocks 03](https://polyhaven.com/a/medieval_blocks_03), Rob Tuytel | `wall_albedo.jpg`, `wall_normal.jpg`, `wall_roughness.jpg` | 2m |
| Floors | [Monastery Stone Floor](https://polyhaven.com/a/monastery_stone_floor), Amal Kumar | `floor_albedo.jpg`, `floor_normal.jpg`, `floor_roughness.jpg` | Approximately 1.8m |

**License: CC0-1.0.** Poly Haven's [official licensing page](https://polyhaven.com/license) confirms that its assets can be redistributed and used commercially without required attribution. The [CC0 public-domain dedication](https://creativecommons.org/publicdomain/zero/1.0/) applies to these texture assets; no website code, logos or other site content is bundled. Credits are retained voluntarily for provenance.

The six sources total 5,075,357 bytes. Godot imports use mipmaps, a 1024px size limit and unflipped OpenGL normals (`compress/normal_map=1` for the two normal maps). Shared StandardMaterial3D resources use repeating world-aligned triplanar mapping, red-channel roughness and normal strength 0.4. Trim reuses the wall textures; area tints do not duplicate image sources. No displacement, collision, actor materials or imported model sources change.

These are bundled offline resources, not runtime downloads. `tools/generate_fortress_assets.gd` still authors only the old original procedural images and must not overwrite this directory. The project's overall source/distribution license is independent of these CC0 assets.
