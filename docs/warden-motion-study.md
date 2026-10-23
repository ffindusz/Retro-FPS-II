# Warden motion study (developer-only)

## Scope and assessment

The user approved packaging the working Windows 0.4.1 baseline and prototyping one enemy's animation. Read-only GLB inspection finds **8,462 triangles, one mesh/material, zero skins and zero animation clips** in the Warden; the Adept is also unrigged. The Warden source remains SHA-256 `969cef958b48e06ce33e40d8efef62797a6cba104a045e4253ac16175135e2d4`.

This first prototype is an **unrigged whole-model motion/timing study**, not a skeletal animation or walk cycle. The left visual approximates the existing whole-model lean/hit scale/death tween; the right adds anticipation/release/recovery, short recoil, a grounded held death pose and subtle idle/in-place locomotion silhouette motion. The blade, feet and limbs cannot move independently. The 0.55-second attack marker is a visual timing reference, not actual damage or a changed combat rule.

No enemy/player/physics/AI/combat-audio/event instances exist in the sandbox. Both sides reuse the accepted normalized Warden and its materials. The main scene, enemy script/scenes, application version, source GLBs and accepted EXE/PCK are unchanged. Prototype paths are excluded from future exports. Nothing in the study is integrated into the game or the portable 0.4.1 ZIP.

## Run and controls

Open `scenes/prototypes/warden_motion_study.tscn` and press **F6**, or run:

```powershell
& .\Godot_v4.7.2-stable_win64.exe --path . scenes/prototypes/warden_motion_study.tscn
```

After a fresh checkout, run the usual editor import first. Keyboard controls:

| Input | Action |
|---|---|
| 0 | Auto sequence |
| 1 / 2 / 3 / 4 / 5 | Idle / locomotion silhouette / attack / hit / death |
| Space | Pause/resume |
| R | Replay current clip (remains paused if already paused) |
| Escape | Quit the standalone preview |

```powershell
& .\Godot_v4.7.2-stable_win64_console.exe --headless --path . --script tests/test_warden_motion.gd
& .\Godot_v4.7.2-stable_win64_console.exe --path . --script tools/capture_warden_motion.gd
```

Captures go to `builds/validation/warden-motion/` at 720p and 1080p. These capture only the scene's rendered viewport, never the desktop. Automated/controlled captures do not establish human visual approval.

## Technical validation — 2026-10-22

- `tools/verify.ps1 -Render` passes editor import, normal game startup, **269 original game checks**, **32 independent motion-study checks**, existing game render checks and eight study captures at 1280x720/1920x1080, with no script/runtime errors. The documented standalone scene command also passes a headless ten-frame startup smoke.
- Motion checks cover 505 candidate-pose samples, finite/bounded transforms, grounding, deterministic sampling, phase continuity, a neutral recovered attack and held death pose, actual candidate application, real keyboard input, pause/replay, time-step equivalence, no actor/collider/navigation creation, constant node counts and disposal/reopening. Review labels fit both logical viewport sizes.
- Temporarily disabling only candidate-transform application caused **two focused failures**; restoring it returned the suite to green. Render inspection also exposed a camera-projected left/right reversal. A new projected-position regression failed before the fix and passes after it; baseline is now genuinely on screen-left and candidate on screen-right. Current suite total is 32 checks.
- Inspected anticipation, release, death and locomotion views across the two resolutions. Labels distinguish baseline/candidate, phase and unrigged/no-damage limitations. These are controlled stationary visual comparisons, not navigation/walking, enemy damage synchronization, user approval or performance evidence. Conservative visual-bounds grounding does not create independently planted feet or a physically articulated fall.
- All **24 offline Python tests** pass (13 prior asset/tool tests plus 11 packaging/isolation tests). The accepted extracted 0.4.1 PCK still passes **269 packaged checks**, and its native startup passes outside the project. Repackaging produces the identical ZIP SHA-256; accepted binaries, source models/audio/navigation and gameplay resources remain unchanged.
- Evidence: `builds/validation/warden-motion-verification.log`, `warden-motion-python-tests.log`, `warden-motion-preview-startup.log`, intentional failure logs `warden-motion-disabled-tests.log` / `warden-motion-reversed-panels-tests.log`, and PNGs in `warden-motion/`. Strict OpenSpec validation passes. No rigging/model service, paid generation, new audio or runtime network code was introduced.

## User test feedback — 2026-10-22

The user reported **"tested it - works!"** after receiving the preview instructions. Record this as a successful user test of the Warden motion study, with no issues reported. It does not separately specify a preference for candidate attack/death timing or authorize rigging, paid services or gameplay integration. The accepted demo and ZIP remain unchanged.

## Follow-up decision

Review **3 Attack** and **5 Death**, pause/replay and compare the two sides. Does the candidate timing read better? The locomotion clip is only a silhouette experiment: rigid feet can still look like sliding if used for navigation. If the direction is useful, the next scoped step is a proper Warden rig with weights plus independently animated legs/arm/blade; then integrate animation with authoritative enemy state and revalidate damage timing. No rigging service, paid generation or new asset license has been authorized or used here.

- [x] User tested the study and confirmed it works.
- [ ] Detailed candidate-timing preference (the local rigging follow-up has already been selected).

The user subsequently selected a local-only Warden rigging follow-up and approved portable Blender installation. That work is recorded separately in [the skeletal prototype](warden-rig-prototype.md); it does not retroactively supply a detailed candidate-timing preference or authorize paid services/gameplay integration. The earlier unrigged study and accepted build remain unchanged.
