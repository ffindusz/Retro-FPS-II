# Meshy.ai → Godot model workflow

The game is intentionally playable before models arrive. Meshy generation runs outside Godot, via manual exports or an explicitly authorized authoring script. The user authorized the first six-model API batch on 2026-10-20. This does not grant a general budget for regeneration or imply distribution rights; review the account's terms before bundling results.

## Art direction and model list

Original dark-fantasy fortress: charcoal stone, weathered iron, muted red cloth, desaturated blue robes, aged brass, and small cyan/gold magic accents. Favor a readable silhouette over surface detail. Do not request named game characters, weapons, logos, or reproductions of existing game assets.

Append these common constraints to each prompt: “single isolated game-ready low-poly 3D object, original design, simple broad shapes, no text, no logo, no background or base scenery, texture atlas up to 1024 square, meter scale.” Triangle budgets are approximately 5,000 for props/weapons and 10,000 for each enemy. Reduce excessive topology before integration; record justified exceptions rather than silently increasing budgets.

The initial API batch uses `meshy-t2.5` Smart Topology at 2,000–8,000 target faces, avoiding the retiring legacy `lowpoly` model. Textures were generated at the API minimum of 2K, with PBR maps; the integrated demo limits them to 1024 through each extracted JPEG's `.import` settings. Exact original prompts and per-model targets are in `docs/meshy-models.json`.

## Opt-in API authoring

`tools/meshy_generate.py` uses Python 3.11+ standard library only. It reads `MESHY_API_KEY` from the process environment or the ignored root `.env` without printing it. It is not part of the exported game. It permits two in-flight assets, checkpoints each paid task before waiting, and never silently creates replacement paid tasks after a failure or ambiguous submission.

```powershell
python tools/meshy_generate.py balance
# Paid stages: only run --submit after explicitly authorizing the cost.
python tools/meshy_generate.py preview --submit
python tools/meshy_generate.py refine --submit
# Resume/download an already submitted stage without creating new paid tasks:
python tools/meshy_generate.py refine
```

The default staging directory is `%LOCALAPPDATA%/Temp/opencode/cinderkeep-meshy-2026-10-20/`, outside the Godot project. Each asset gets a sanitized `record.json`, geometry-only `preview.glb` and `preview.png`, then textured `model.glb` and `textured.png`. Downloads use HTTPS without forwarding the API authorization header; records include checksums, not secrets or signed URLs. Back up these staging results once rights are reviewed; Meshy API retention is limited. A `SUBMITTING` or `UNKNOWN` checkpoint requires reconciling the request in Meshy's dashboard before trying again, not deleting the record and resubmitting.

Pricing checked on 2026-10-20: [Meshy API pricing](https://docs.meshy.ai/en/api/pricing), 5 credits per T2.5 preview plus 10 per 2K refine, 90 total for six models. No paid auto-retries or additional variants are included in this authorization. [Terms reviewed](https://www.meshy.ai/terms-of-use), version dated September 19, 2026, sections 2.4 and 3.2: paid-plan output ownership and free-plan CC BY 4.0 treatment differ. The API balance does not identify the subscription/license tier; do not infer it from a working key.

| Asset ID | Suggested prompt subject | Wrapper / target |
|---|---|---|
| `weapon-cleaver` | Broad weathered iron cleaver, short wrapped brown grip, small aged brass guard, strong asymmetric blade silhouette; no hands | `scenes/weapons/melee_viewmodel.tscn`, grip pivot |
| `weapon-staff` | Rough dark wood ember staff, two brass prongs holding a small cyan crystal, no ornate thin filigree; no hands | `scenes/weapons/magic_viewmodel.tscn`, grip pivot |
| `enemy-warden` | Hoodless ancient stone-faced fortress warden, muted red heavy tunic, broad iron shoulder plates, one simple chopping blade, standing neutral stance | `scenes/enemies/melee_enemy.tscn`, feet pivot, about 1.8 m tall |
| `enemy-adept` | Thin masked crypt adept in desaturated blue robes with a simple amber-tipped staff, standing neutral stance, distinct readable silhouette | `scenes/enemies/ranged_enemy.tscn`, feet pivot, about 1.8 m tall |
| `prop-torch` | Simple iron wall torch bracket with short wood torch and small stylized flame, no wall section | `scenes/props/torch.tscn`, flame-centered pivot |
| `prop-urn` | Squat aged stone funerary urn with a broad neck, worn brass ring and plain carved bands, no lettering | `scenes/props/urn.tscn`, ground pivot, about 0.8 m tall |

Static enemy models are sufficient for this demo: the wrapper supplies damage flashes, windup motion, and death transforms. Skeletal animation is optional future work, not an import prerequisite. The key and flasks can remain original procedural geometry. Walls, floors, cover, and navigation remain authored Godot geometry.

### Separate authorized Warden animation trial — 2026-10-23

The user later authorized one original-Warden upload/rig and exactly actions 0/21/219 under a **14-credit cap with no automatic paid retries**. `tools/meshy_animation_ab.py` implements that fixed trial independently of the original model-generation tool: free balance/library preflight, before-POST 5+9 reservations, task-ID checkpoints, ambiguous/failure guards, a concurrency lock and sanitized downloads/records. Exactly 14 credits were consumed; the account moved from 1,380 to 1,366. This is not a standing budget for additional operations.

The completed trial's raw files/checkpoint are in `%LOCALAPPDATA%/Temp/opencode/cinderkeep-warden-meshy-ab-2026-10-23/`, backed up to ignored `builds/authoring/warden-meshy-ab/`. Use `python tools/meshy_animation_ab.py preflight` for read-only checks or `python tools/meshy_animation_ab.py run` **without `--submit`** to resume existing tasks. Do not clear checkpoints or start another paid trial without new approval. `tools/prepare_meshy_ab.py` and `tools/analyze_meshy_ab.py` inspect existing files offline. [Actual A/B scope, Service Asset rights basis, findings and preview controls](warden-meshy-animation-ab.md) are recorded separately; no result replaces accepted gameplay/builds.

### Animation-ready Warden pilot — 2026-10-23

The user subsequently approved a distinct **90-credit** pilot: three standard Meshy 7.1 body previews (20 each), one selected 2K PBR refine (10), rig (5) and five presets (15). `docs/warden-pilot-plan.json` fixes the original prompts, A-pose request, 8k target and actions 0/21/219/178/8. `tools/meshy_warden_pilot.py` reserves/checkpoints before each POST, locks the plan and downstream selection, resumes saved IDs and refuses paid replacement/extra branches. All six planned requests succeeded for exactly 90 credits (1,366 → 1,276); the user selected **c02 Brigandine** after actual views. No other body was textured/rigged, and no Adept/extra model or action was purchased.

Raw/checkpoint staging is `%LOCALAPPDATA%/Temp/opencode/cinderkeep-warden-pilot-2026-10-23/`, backed up under ignored `builds/authoring/warden-pilot/`. `python tools/meshy_warden_pilot.py finish --candidate c02` **without `--submit`** is resume-only; this completed budget is not permission to clear records or start another paid trial. Offline preparation tools preserve raw metadata/hashes and validate UV-atlas compatibility before restoring selected PBR maps. Candidate and selected-pilot assets remain under excluded `assets/prototypes/warden-pilot/`. [Pilot findings, actual costs, source hashes, controls and review limits](warden-animation-ready-pilot.md) document bent-elbow/noncompliant variants, the selected body and separately attached accepted Iron Blade. Gameplay/collision/navigation/version and accepted exports remain unchanged.

## Export and rights gate

1. Generate/review each model using the user's own Meshy account. Record generation/export identifiers, prompt, generation date, and the account plan/license terms that applied. Do not expose credentials.
2. Confirm redistribution rights for geometry and textures, including any uploaded image/reference source. Record required attribution. If rights are unknown, mark **unresolved** and **do not bundle** the asset in `assets/` or an exported PCK. Keep it outside the project until cleared.
3. Export **GLB** with embedded textures (preferred) or glTF with all referenced texture files. Keep an unchanged source copy outside this project if cleanup/decimation is necessary. No Blender installation is required for an already suitable GLB.
4. Place cleared deliverable models in `assets/models/<asset-id>/` with stable filenames. Update the manifest before marking them final.

## Import and normalization

1. Let Godot import the GLB and review the Import dock. Keep scale at 1 if the source is in meters; otherwise record the conversion. Check normals, opaque/masked materials, backface behavior, embedded albedo/normal/roughness textures, and missing-texture warnings. Do not generate collision from decoration or first-person meshes automatically.
2. Create or update the corresponding normalized visual scene in `scenes/models/`. Instance the imported GLB there, then assign that scene to the gameplay wrapper's exported **Model Scene** and set **Use Placeholder** to **false**. For the ranged enemy, override the inherited model scene on its root. The wrapper instances it under **VisualRoot** at startup; do not attach gameplay scripts to the imported GLB or add a second duplicate instance. Pickups without a `model_scene` property can use an authored visual child directly.
3. Adjust the imported child's scale/rotation/offset, not the gameplay root. Godot is Y-up; this game's actors face **-Z**. Enemy feet sit at local Y=0, centered on the capsule. Weapon origins are at the grip; keep the wrapper's first-person framing separate from a later world pickup's transform.
4. Preserve existing capsule shapes, pickup areas, navigation agents, and torch lights. Imported enemy meshes must fit the existing capsule or receive a deliberate authored collision/navigation update; complex triangle collision on dynamic actors is not acceptable. Urns are intentionally nonblocking decorations.
5. Reimport the GLB once and confirm wrapper adjustments survive. If the imported hierarchy changes, repair only the visual child, not combat/session logic.

## In-game review

- Both weapons are visibly 3D, correctly gripped/framed, and animate without clipping through walls or hiding the crosshair.
- Both enemy silhouettes are distinct. Windup, hit, and death feedback remain readable without a rig. Capsules, navigation, and attacks match the model's apparent size.
- Torch/urn scale and materials match the fortress; torch light remains independent of the imported visual.
- Test both supported resolutions, restart repeatedly, and run `tools/verify.ps1 -Render` plus a real playthrough.
- Re-profile after model replacement; record triangle/texture counts and exceptions in the manifest. The placeholder performance sample does not predict final art performance.
- Mark tasks 7.3–7.5 complete only after supplied models, resolved rights, import, and gameplay review. Otherwise continue to label builds **placeholder prototype**.
