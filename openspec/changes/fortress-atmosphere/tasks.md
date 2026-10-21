## 1. Baseline and presentation boundary

- [x] 1.1 Record combat-polish 0.2.1's 196 gameplay/model/audio checks, eight authoring tests, source model/SFX hashes, collider/gameplay-placement/navmesh fingerprints, and fixed entrance/courtyard/crypt/key/exit camera views before editing presentation; preserve prior acceptance task states.
- [x] 1.2 Add a small level-owned presentation boundary and developer atmosphere toggle, default on, with the previous flat/static world available when off; keep geometry-only navigation authoring independent of a player or active ambience.

## 2. Original environment materials

- [x] 2.1 Author deterministic tileable wall-stone, flagstone-floor and worn-trim albedo/roughness images offline, within six 512×512 textures; bundle them with repeat/mipmap imports and provenance/seed documentation, without paid services or external downloads.
- [x] 2.2 Create cached shared StandardMaterial3D family/area variants and apply consistent documented world-scale mapping to existing surfaces, with restrained gate accents and unchanged imported model materials/source hashes.
- [x] 2.3 Add resource-size/sharing/fallback checks and capture matching close/wide surface views to review tiling, seams, orientation, scale and Compatibility rendering.

## 3. Readable environment lighting

- [x] 3.1 Tune warm torch/cool moon/ambient contrast with a nonzero visibility floor; preserve the six torch locations/ranges, existing shadow-source count, enemy perception, and isolated weapon lighting.
- [x] 3.2 Implement deterministic slow torch energy modulation clamped to ±8%, with per-torch phases, no rapid toggles/range changes, pause freezing and fresh-run reset.
- [x] 3.3 Test energy/time/reset/light-count bounds and render both-resolution enemy, pickup, key/exit and HUD views for readability across the tuned areas.

## 4. Nonblocking architectural dressing

- [x] 4.1 Add simple frame/trim/pillar accents within existing solid footprints or wall margins; reuse urns in sparse fixed clusters with at most twelve total and keep exactly six torches, without new collision, rooms, roofs or cover.
- [x] 4.2 Strengthen courtyard/crypt/gate/key landmarks through materials and restrained decoration while retaining signs, E feedback, objective/item positions and clear approach/retreat/attack lanes.
- [x] 4.3 Verify canonical static collider/gameplay-placement fingerprints and navmesh hash are unchanged, decorative counts are stable across runs, and existing combat, zero-mana key/exit and reset invariants still pass.

## 5. Bounded ambience and controls

- [x] 5.1 Author and bundle original quiet wind/crypt loops in a separate audio directory, with documented source parameters/provenance, valid forward-loop metadata, bounded unclipped audio and technically checked loop boundaries; preserve all eleven accepted SFX hashes.
- [x] 5.2 Add a run-owned two-player ambience controller with complementary, approximately one-second crypt doorway blends and conservative default gain/headroom, independent of the one-shot SFX voice service and gameplay state.
- [x] 5.3 Add an independent keyboard/mouse-accessible pause-menu Ambience volume/mute slider; retain both session volume values across restarts without changing SFX behavior or overflowing either test-resolution canvas.
- [x] 5.4 Wire start/pause/resume/terminal/menu/disposal behavior so blend/playheads freeze on pause, only two loops exist in an active run, old loops stop/free, and only game-created buses are removed; test repeated transitions, mute, independent controls and no replay/stacking.

## 6. Comparison, validation and Windows delivery

- [x] 6.1 Run all retained gameplay/model/audio and authoring tests plus new atmosphere checks; capture matching before/after views at 1280×720 and 1920×1080, including active feedback and both volume controls.
- [x] 6.2 Profile equivalent fixed views on the recorded reference PC, record texture/material/prop/light/audio counts and measured deltas, and reduce presentation complexity if it materially regresses performance without changing renderer or gameplay.
- [x] 6.3 Rebuild the Windows export, verify bundled materials/loops/models/SFX through packaged-resource tests from an external working directory, and complete native startup/cleanup smoke checks without authoring tools or runtime downloads.
- [ ] 6.4 Complete and record a human visual review for stone scale/seams, lighting and flicker comfort, enemy/resource/objective readability, uncluttered routes, and improved environmental identity; leave pending if unreviewed.
- [ ] 6.5 Complete and record a human ambience/listening/full-run review for loop seams, doorway transition, default mix against combat/pickup cues, independent volume/mute, timing/difficulty, pause/results/restart and offline native play; do not infer unreported prior acceptance outcomes.
- [x] 6.6 Update controls, asset/audio provenance, before/after validation, performance notes, fallback instructions and known limitations; keep missing human checks explicit and reconcile active-change specs before any separately requested archive.
