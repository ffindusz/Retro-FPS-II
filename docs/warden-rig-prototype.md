# Local Warden skeletal prototype

## Authorization and tooling

On 2026-10-22 the user approved a **local-only** Warden rigging workflow and installing portable Blender LTS. This does not authorize paid generation, remote rigging, uploads, new asset purchases or replacing the live enemy.

- Official portable Windows x64 **Blender 4.5.15 LTS**, build `5afeabba6097`.
- Download: `https://download.blender.org/release/Blender4.5/blender-4.5.15-windows-x64.zip` (398,649,826 bytes).
- Verified against the official `blender-4.5.15.sha256`: `52dd02fd74877fa08e74b67d7854cf32468a232c02aaa19b6844c91285574f8d`.
- Installed outside the repository at `%LOCALAPPDATA%/Temp/opencode/blender-4.5.15-windows-x64/`; no registry/PATH changes. Authoring runs with `--background --factory-startup --disable-autoexec`. No new service/account/add-on is required; Blender is not a runtime dependency or bundled tool.

## Source assessment

The unchanged original `assets/models/enemy-warden/model.glb` has SHA-256 `969cef958b48e06ce33e40d8efef62797a6cba104a045e4253ac16175135e2d4`, 7,327 render vertices, 8,462 triangles and zero skins/clips. Blender imports the same vertex/triangle counts. The existing normalization is baked into the derivative only: approximately 1.8063m tall, Godot Y-up / -Z-forward.

Coincident-position connectivity analysis (without welding/modifying the asset) finds three components:

| Region | Vertices | Interpretation / treatment |
|---|---:|---|
| Main body | 6,821 | Connected body, armor and coat/cape; fitted anatomical weights require deformation review |
| Carrying hand/grip | 326 | Small separate region at the right wrist; rigid hand weights |
| Blade | 180 | Separate approximately 0.708m-long region; one rigid weapon-bone influence |

No geometry cuts or replacement textures are needed for this initial approach. Connectivity alone is not a claim of production-ready topology: shoulder/hip pinching and cape/armor stretching remain risks. `tools/warden_rig_geometry.py` provides read-only assessment and inspectable deterministic region/weight helpers; `builds/authoring/warden-rig/mesh-assessment.json` records the Blender import assessment.

## Scope

This is a technical, separately reviewed skeletal prototype with humanoid bones, normalized body weights, a rigid hand-following blade and Idle/Walk/Attack clips. The existing main scene, enemy scripts/scenes, original source models/materials, version, gameplay timings and accepted EXE/PCK/ZIP must remain unchanged. No physics/gameplay events or damage are added to the preview. The 0.55s attack reference is visual-only, not an integration with AI damage.

The generated `.blend` is editable locally; the authoring script, derived GLB and provenance make the work inspectable/rebuildable. No fingers/facial rig, cloth simulation, production animation quality, perfect foot planting or public-release approval is claimed.

## Outputs and authoring

- Derived geometry/skin/clips: `assets/prototypes/warden-rig/warden_rig.glb` (original topology/UV inventory retained, no embedded images).
- Current GLB: **481,068 bytes**, SHA-256 `4299394ac1d39477658315a9095df484782e9105557d1aab24f61d7f4693018b`.
- Provenance: `assets/prototypes/warden-rig/provenance.json`, including original/derived/authoring hashes, Blender build, bone/region counts, clip lengths and source-script hashes.
- Editable Blender source: `builds/authoring/warden-rig/warden_rig.blend` (generated/ignored, available locally, not a game runtime dependency).
- The Godot preview reuses the **exact original Warden material and 1K textures**, rather than duplicating/recompressing accepted images. The derivative GLB viewed alone in another application has no textured material; use the Godot preview or editable `.blend` for appearance review.

PowerShell rebuild (use a Blender path appropriate to your machine):

```powershell
$blender = "$env:LOCALAPPDATA\Temp\opencode\blender-4.5.15-windows-x64\blender.exe"
& $blender --background --factory-startup --disable-autoexec --python-exit-code 1 --python tools/author_warden_rig.py -- --assess-only
& $blender --background --factory-startup --disable-autoexec --python-exit-code 1 --python tools/author_warden_rig.py -- --replace-generated
& .\Godot_v4.7.2-stable_win64_console.exe --headless --path . --editor --import
```

The default authoring command without `--replace-generated` refuses existing outputs. Explicit replacement is allowed only when every existing GLB/`.blend` matches its prior provenance hash; modified user work is preserved. A fresh checkout can rebuild when the tracked GLB is present but the ignored `.blend` is absent. Source checksums are checked before import. Saving an edited `.blend` deliberately trips this guard: use a separate manually edited authoring path rather than overwriting it with the generator.

The fitted 21-bone hierarchy has Root/Pelvis/Spine/Chest/Neck/Head, mirrored shoulder/upper-arm/forearm/hand and thigh/shin/foot chains, plus `Weapon.R` parented to `Hand.R`. Body weights use semantic regions followed by six inverse-edge-length topology smoothing passes, capped at four normalized influences. Analysis/weight smoothing uses coincident positions without welding the actual geometry or UVs. The disconnected hand/grip and blade remain rigid. The asymmetrical carrying-arm rest pose is fitted behind the torso; the initial naive region boundary was corrected to avoid wrist slivers.

The last same-tool rebuild produced the identical GLB hash. The editable `.blend` is about 10 MB and carries editor/save metadata, so byte-identical `.blend` rebuilds are not promised. The two hash-pinned Python authoring sources have narrowly scoped LF checkout rules in `.gitattributes` to keep their provenance hashes stable on Windows.

Clips are locally keyed and sampled at 30fps: **Idle 2.0s**, **Walk 1.0s**, **Attack 1.4s**. Idle/Walk endpoints match. No horizontal root motion or gameplay callbacks exist. Walk is an in-place gait without IK/stride matching to navigation; Attack has anticipation through 0.55s, release and recovery, not authoritative combat damage. All action data is editable in Blender's Action Editor after selecting `WardenRig`; its named NLA tracks are muted in the saved authoring scene so they do not layer accidentally.

## Run the skeletal preview

Open `scenes/prototypes/warden_rig_preview.tscn` and press **F6**, or:

```powershell
& .\Godot_v4.7.2-stable_win64.exe --path . scenes/prototypes/warden_rig_preview.tscn
```

| Input | Action |
|---|---|
| 0 | Auto sequence |
| 1 / 2 / 3 | Idle / in-place Walk / Attack |
| Space | Pause/resume |
| R | Replay current clip (remains paused if paused) |
| B | Toggle skeleton overlay |
| V | Front / side / back comparison views |
| Escape | Quit standalone preview |

The **left** figure is the original static visual; the **right** is the genuinely skinned derivative. The new preview shares only the old sandbox's stage concepts and original material; the earlier whole-model study remains available unchanged. No player/enemy scripts, gameplay colliders, navigation, damage, projectiles or combat audio are instantiated. Prototype assets/scenes/scripts are excluded from future exports, and neither accepted binaries nor ZIP are re-exported.

```powershell
& .\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/test_warden_rig.gd
& .\Godot_v4.7.2-stable_win64_console.exe --path . --script tools/capture_warden_rig.gd
python -m unittest discover -s tests -p 'test_*.py' -v
```

## Technical evidence — 2026-10-22

- `tools/verify.ps1 -Render` passes editor import, normal project startup, **269 game checks**, the unchanged **32 whole-model-study checks**, and **39 skeletal-preview checks**. Existing game renders, eight prior study captures and **18 new rig captures at 1280x720/1920x1080** complete without script/runtime errors. The documented standalone rig-scene launch also passes a ten-frame headless startup with empty stderr.
- All **39 offline Python tests** pass: 24 prior tests plus 15 rig structural/weight/provenance/guard/isolation tests. These check original/derived/script hashes, actual joint/weight attributes and inverse binds, all normalized finite four-slot weights, rigid blade/hand regions, identical weights across coincident UV/normal seams, unchanged geometry/UV inventories, three finite bone clips, loop endpoints, stationary root, actual limb rotation, no embedded/remote images and safe rebuild guards.
- Godot checks independently verify the imported 21-bone skin, exact rest-pose reconstruction for all 7,327 vertices using actual bind matrices, independently moving skinned feet/hand/blade with a fixed model root, opposite leg strides, rigid blade length/hand-relative attachment, finite poses, loop endpoints, clip switching without retained arm poses, real keyboard controls, pause/replay, overlays/views, layout and disposal/reopening. Foot-height checks cover representative vertices, not a proof of perfect planting.
- Temporarily freezing bone playback at time zero caused **five focused failures**, including actual foot/hand/blade motion and arm rotation; restoring playback returned checks to green. These fail even while the static model and skeleton still exist. Intentional failure evidence is `builds/validation/warden-rig-disabled-animation.log` (then a 38-check iteration; the final suite adds a clip-switch reset check).
- Early side-view inspection exposed severe wrist slivers from a hard anatomical cutoff. Refitting the asymmetric carrying arm, including the low wrist/finger region and topology-smoothing weights corrected the visible spikes. At the prepared-attack frame, the maximum growth of an original sub-centimeter edge is now **0.006576m** (about 6.6mm), below the 2cm focused regression bound. This is one deformation sentinel, not a claim that all edges/garment regions deform optimally.
- Inspected rest, gait, prepared/released attack, side/back views and skeleton overlays across both resolutions. Real limb articulation and retained original appearance are visible. This is controlled visual inspection, not user approval, an animation-quality certification, sustained performance measurement or live AI/damage integration.
- The accepted PCK again passes **269 checks** with an external runner/working directory, and the accepted native EXE passes headless startup with exit 0 and empty stderr. Offline hash checks confirm the original source model, accepted EXE/PCK and portable ZIP remain unchanged. No game re-export occurred and no paid services/uploads were used. Strict OpenSpec validation passes.
- Logs: `builds/validation/warden-rig-{authoring,import,verification,render,offline-tests,preview-startup}.log`, `warden-rig-baseline-{packaged-tests,native-startup}.log`, plus PNGs in `builds/validation/warden-rig/`. The latest rig renders are also captured by the full verification log.

## Review limits and next gate

This is a **working technical rig, not a production-ready animated enemy**. The topology is still the original generated rest mesh: arm/torso transitions and coat/armor may pinch or stretch in extreme poses, and there is no cloth simulation, finger articulation, foot IK or root-motion/navigation matching. Small-edge spike checks catch the severe initial wrist artifact, not every deformation defect. The planted-foot and combat-feel questions require human review; technical passes are not animation-quality acceptance.

- [ ] Review Walk and Attack from front, side and back, especially shoulders/elbows, hips/coat and cape.
- [ ] Check that the blade remains gripped and rigid throughout attack/recovery.
- [ ] Decide whether to refine mesh/weights/clips before a separately scoped gameplay integration.
