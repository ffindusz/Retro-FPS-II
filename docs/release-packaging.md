# Portable Windows playtest bundle

**Current-build note:** this page describes the frozen accepted **0.4.1 ZIP**. The project now targets a separate [animated-Warden 0.5.0 Windows folder](warden-runtime-integration.md); neither the old binaries/ZIP nor this packager's pinned inputs were overwritten. New 0.5.0 controls/credits/record live under `docs/release/0.5.0/` and `docs/release/release-0.5.0.json`. No new ZIP is implied.

## Accepted baseline

The user reported **"build works!"** for the exported Windows 0.4.1 build on 2026-10-22, then approved packaging that checkpoint before an isolated one-enemy animation prototype. This is general native-build confirmation, not a report of every detailed/offline acceptance case. `docs/release/release-0.4.1.json` pins the original EXE/PCK sizes and SHA-256 hashes. The binaries, main game and version are unchanged by packaging or the developer prototype.

## Bundle and contents

`builds/releases/Cinderkeep-0.4.1-windows-x64.zip`

- **76,685,288 bytes** (about 77 MB / 73.1 MiB).
- SHA-256: `e60788ce5615026cc8fb8df7530e9556ae349b638da87db66cf8ed0477d1b815`.
- Exactly seven adjacent files: `Cinderkeep.exe`, `Cinderkeep.pck`, `README.txt`, `CREDITS.txt`, `GODOT-LICENSE.txt`, `GODOT-COPYRIGHT.txt`, `SHA256SUMS.txt`.
- Extract the whole ZIP and launch `Cinderkeep.exe`; keep the PCK beside it. No installation, editor, templates, account or runtime network connection is required.
- Player README includes controls, objective, volume controls and current limitations. Credits identify original assets, Meshy AI origin/paid-plan review and Poly Haven's CC0 stone authors. Verbatim Godot 4.7.2 engine/component notices are bundled with official source URLs/byte hashes in `docs/release/engine-notices.json`.

This is a local playtest bundle, **not** public publishing or a project-wide license grant. The owner still decides the source/distribution license and reviews any account-specific agreements before public release. Prototype files and developer tools are not bundled. No additional model-generation or rigging credits were spent.

## Reproduce and verify

With the original accepted files still at `builds/windows/`:

```powershell
python tools/package_release.py
python -m unittest discover -s tests -p 'test_*.py' -v
```

The packager is offline and uses only Python's standard library. It verifies the pinned binary sizes/hashes and engine-notice provenance, reads an explicit six-file allowlist, generates per-file SHA-256 sums and writes fixed ZIP metadata/order. Repeating identical inputs yields the same ZIP hash. A mismatched input or different existing output fails without overwriting that output. Use `--output <new-path.zip>` for another location. It never re-exports Godot resources or globs the workspace/build directory. Release text is checked out with LF via the narrowly scoped `.gitattributes` rule so notices and ZIP input bytes remain stable on Windows.

The ZIP passed CRC and every included-file checksum. It was extracted to a new approved temporary directory outside the repository; the extracted PCK passed **269 packaged checks** using the editor engine/external runner, and the extracted native EXE passed `--headless --quit-after 10` with exit 0 and empty stderr. Evidence is `builds/validation/bundle-0.4.1-{packaged-tests,native-startup}.log` and `bundle-0.4.1-validation.json`. This does not claim an explicitly disconnected interactive win/lose/restart run.

All **11 packaging/isolation regression tests** pass (24 offline Python tests overall), covering exact allowlists/checksums, identical repeat output, preservation of a different existing output, changed artifact bytes/sizes, missing/modified/mismatched engine notices, wrong release versions, extra artifact entries and prototype exclusion from the normal game/export preset. A second real packaging run verified the same ZIP hash; its record is `builds/validation/bundle-0.4.1-manifest.json`.

The [Warden motion study](warden-motion-study.md) remains a separate developer preview. No game re-export is necessary to review it, and it is deliberately absent from this accepted ZIP.
