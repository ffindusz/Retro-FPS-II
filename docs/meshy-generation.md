# First Meshy model batch — 2026-10-20

The user explicitly authorized generation using the locally configured API key after a read-only balance check showed 1,470 available credits. Authorization covers one geometry and one texture pass for each of the six planned demo assets, not open-ended retries, subscription changes, or purchases of additional credits.

## Configuration and cost

- Geometry: `meshy-t2.5`, `model_type: smart-topology`, triangle output, explicit per-model face targets.
- Texture pass: inherited preview model, 2K textures with PBR enabled, GLB output.
- Inputs: original text descriptions in `docs/meshy-models.json`; no reference images, existing game assets, or personal data uploaded.
- Pricing reference: <https://docs.meshy.ai/en/api/pricing>, checked 2026-10-20. Estimate: 6 × (5 mesh + 10 texture) = **90 credits**.
- All six geometry previews and all six texture passes **succeeded and were downloaded**. Actual reported consumption: **30 mesh + 60 texture = 90 credits**. Final queried balance: **1,380 credits**.
- The staff's first download failed after its successful texture job; a read-only resume downloaded that existing result. No additional generation or credits were used for the retry.

## Geometry preview inventory

| Asset | Preview task ID | Observed triangles | Review notes |
|---|---|---:|---|
| `weapon-cleaver` | `01a15a14-beba-701d-b2a3-4d902cef8cb8` | 3,086 | Coherent, upright, single weapon; more sword-like than the requested broad cleaver. Keep the first variant rather than spend additional credits without approval. |
| `weapon-staff` | `01a15a14-bec4-76e0-98fb-e50f9c2146ab` | 4,229 | Distinct crystal-topped silhouette and intact shaft/prongs. |
| `enemy-warden` | `01a15a15-397c-716d-8118-ed3fbe590aec` | 8,466 | Complete masked armored humanoid, feet visible, lowered blade. |
| `enemy-adept` | `01a15a15-647f-7205-a451-a39bea20958b` | 7,384 | Complete hooded humanoid with tall staff, distinct from warden. |
| `prop-torch` | `01a15a15-c801-712a-8402-b04f72de3dbe` | 2,050 | Torch/bracket/flame silhouette; has an extra lower basket to review during placement. |
| `prop-urn` | `01a15a16-092b-70f0-bd88-d754428eabc1` | 1,966 | Coherent decorative urn; lidded rather than the prompted open neck. |

All preview GLBs are valid glTF 2.0 binaries without external resource links, skins, or animation. All observed geometry counts fit the demo's budgets. These are visual/metadata checks only, not proof of in-game scale, orientation, materials, or animation quality.

## Completed textured models

| Asset | Texture task ID | Final triangles | GLB bytes |
|---|---|---:|---:|
| `weapon-cleaver` | `01a15a17-89ce-754d-a7a6-c620a47124d3` | 3,086 | 7,526,076 |
| `weapon-staff` | `01a15a17-378d-7288-a513-3724b1a4da0e` | 4,224 | 7,427,792 |
| `enemy-warden` | `01a15a18-094a-7111-9e9e-da0223e99898` | 8,462 | 6,967,512 |
| `enemy-adept` | `01a15a18-22aa-76bd-a5dc-272a0ef2da97` | 7,382 | 6,469,384 |
| `prop-torch` | `01a15a18-9f91-7506-b5fe-2eb110f40cd9` | 2,048 | 5,811,136 |
| `prop-urn` | `01a15a18-b6eb-7344-b5b4-308ea2a313e7` | 1,966 | 7,198,868 |

Each final GLB has one material and three embedded 2048×2048 JPEG texture images, no external resource links, no required glTF extensions, and no skins/animations. Inspected all six textured thumbnails and the labeled contact sheet: cyan staff crystal, amber enemy staff, distinct burgundy/blue enemies, torch, and urn are present. The documented geometry deviations remain; no extra variants were purchased. Following the user's paid-plan confirmation, these models were copied unchanged to `assets/models/<id>/model.glb`, normalized through `scenes/models/`, and reviewed in the actual Godot level. Extracted runtime textures are capped at 1024px. See `docs/asset-manifest.md` for transforms and `docs/validation.md` for checks.

Final model SHA-256 checksums:

```text
weapon-cleaver  7fc4e7c6b6b9c6586511c97c0acabcfee6dea34566554e2d35cf7a5c5eb3e9e6
weapon-staff    0bc45c47f130b513a5341d666f7d9350e70a3329d662c64e6fb606ce40ca690b
enemy-warden   969cef958b48e06ce33e40d8efef62797a6cba104a045e4253ac16175135e2d4
enemy-adept    32c0f4108f64ec007d76fd1d1f53f7ef6650216ad9d4c31aa62b4e2e911bd53c
prop-torch     564039b26f30d78b1473b5355bcf87398474de742cd77cdecdc1ceeda91cbdbb
prop-urn       ea870451d1d7d24375ccd4f829a19f4de5f455fa7494afda683799c79ace2270
```

## Files and provenance

Staging location, outside the Godot project:

`%LOCALAPPDATA%/Temp/opencode/cinderkeep-meshy-2026-10-20/`

Each asset folder contains a sanitized `record.json` with original prompts, request parameters, task IDs, stage status, actual reported credit consumption, timestamps, download filenames, byte sizes, and SHA-256 checksums. Preview files are `preview.glb` and `preview.png`; final textured files are `model.glb` and `textured.png`. The staging root also contains `contact-sheet-textured.png` and `cinderkeep-source-models.zip`, bundling the six asset folders and labeled textured overview. Credentials and signed download URLs are not stored in these records or archive. Local copies are essential because Meshy API output retention is limited.

An optional labeled overview can be produced without new dependencies on Windows:

```powershell
.\tools\meshy_contact_sheet.ps1 -Stage preview
.\tools\meshy_contact_sheet.ps1 -Stage textured
```

## Rights and integration gate

Terms reference: <https://www.meshy.ai/terms-of-use>, last updated September 19, 2026. Section 3.2 distinguishes paid-plan ownership from free-plan CC BY 4.0 output. **The user confirmed a paid monthly subscription on 2026-10-20.** The project review therefore applies the paid-customer output provision for these user-authorized generations. Inputs are original text only, with no uploaded reference assets; reviewed thumbnails show generic original fantasy designs. No separate account-specific agreement has been supplied, and no exclusive copyright or legal guarantee is asserted. Preserve AI-origin metadata and provenance. This resolves the project's account-plan gate for bundling these six assets; the owner remains responsible for any account-specific terms and public-release review.

Generation and the project's rights review are complete (task 7.3). The six normalized visual wrappers are integrated with unchanged gameplay collision, materials/scale/orientation checks, procedural fallbacks, and rendered combat/death/wall/resize review. Human playthrough/balance and final offline native-binary acceptance remain separate from model integration.
