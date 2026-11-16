## Context

Combat-polish 0.2.1 is implemented in Godot 4.7/GDScript with the Compatibility renderer, six Meshy models, eleven accepted combat/pickup SFX, 196 source/packaged checks, and eight authoring-tool tests. The user reports sounds work, melee improved, and difficulty is okay; the original timed run was roughly five minutes. Detailed/offline acceptance in the two prior changes is still open and is not closed by this proposal.

`scripts/level.gd` builds a fixed entrance, courtyard, and crypt from simple boxes, with flat colors, a cool directional light, six warm non-shadowed torch lights, four nonblocking urns, and three world signs. Geometry, navmesh, encounters, pickups, and objective positions are already functional. The isolated weapon viewport has its own camera/lighting and must not be altered by a world-lighting pass.

The canonical spec registry is empty because both preceding changes remain unarchived. Four additive atmosphere capabilities build on their implemented behavior; no earlier acceptance task or spec is silently rewritten.

## Goals / Non-Goals

**Goals:**
- Give the same level readable stone surfaces, architectural identity, and warm/cool depth without hiding threats or objectives.
- Add subtle torch motion and sparse, purposeful dressing using existing assets and simple original geometry.
- Add quiet wind/crypt ambience with smooth transitions, independent volume, and clean lifecycle behavior.
- Keep the current controls, combat/SFX, gameplay geometry and placement, offline operation, and modest asset/performance footprint.

**Non-Goals:**
- New gameplay areas, roofs/ceilings, collision, cover, secrets, puzzles, balance changes, actors, resource locations, or objectives.
- New Meshy models, paid generation, external texture/audio downloads, rigs, music, or runtime procedural asset generation.
- Forward+ migration, volumetric fog, screen-space effects, dynamic-shadow expansion, or a general settings screen.
- Calling new visuals/ambience user-approved or completing old acceptance work without new evidence.

## Decisions

### 1. Original baked textures with shared, world-scaled materials

Create deterministic offline Godot authoring for three tileable families: rough block-stone walls, flagstone floors, and worn stone trim. Bundle at most six 512×512 images initially (albedo and roughness per family), mipmapped and repeating, plus a restrained solid-color iron/brass gate accent. Use StandardMaterial3D world-aligned/triplanar mapping where appropriate so a long wall or differently sized box does not stretch its stone pattern. Start near two meters per texture tile and inspect it against the existing approximately 1.8m enemies; keep orientation and scale consistent across neighboring pieces.

Cache shared material resources by family/area variant, rather than allocating a new texture/material per block. Keep the courtyard slightly cooler and the crypt more muted, using broad color/roughness differences instead of busy contrast or noisy displacement. Preserve all Meshy source files, normalized wrappers and their 1024px import limits. Do not overwrite shared imported actor materials. Record texture seeds/settings and provenance in the manifest; play/export never invokes authoring code.

**Alternative:** Downloaded texture packs introduce licensing and network work. Runtime procedural shaders/displacement increase renderer cost and can change apparent surfaces. Per-object UV scaling stretches the pattern across the current variable-size boxes.

### 2. Separate presentation from gameplay geometry and support a developer fallback

Add a small environment-presentation helper under the level that applies materials and decorative meshes to the existing world. Keep collision construction and `build_geometry()` usable by the navigation authoring tool without a player or running ambience. A developer-only atmosphere toggle defaults on and can restore the pre-pass world presentation for troubleshooting/comparison; no new player-facing graphics settings screen is needed.

Before changes, capture a canonical fingerprint of static collider shapes/transforms/layers and gameplay placements. The new presentation must leave that fingerprint, the baked navigation resource, gameplay item counts, stats and objectives unchanged. New dressing has no collision and must not look like usable cover placed in an otherwise open route. Do not add visual walls/ceilings across empty gameplay space or pretend that a new arch blocks physics when it does not.

**Alternative:** Rebuilding the fortress with new imported geometry or changing physics to match a large visual remodel would invalidate the accepted combat/route baseline and require a different scope.

### 3. Warm/cool lighting with restrained deterministic flicker

Retain the six existing torch locations and non-shadowed OmniLights, and the existing directional shadow source. Tune environment/ambient, moon and torch values for warm pools against cooler stone/shadows. Keep a nonzero ambient floor, avoid crushed-black crypt routes, and inspect both enemy silhouettes, flasks, key, gate, and crosshair at each supported resolution. Do not modify player viewmodel lighting, enemy perception, physics LOS, or attack timing.

Give each torch a deterministic phase offset and slow smooth energy modulation around its authored base energy, clamped to ±8%, with component frequencies below 3Hz. Never toggle a light on/off, modulate its range into a gameplay boundary, or add flickering shadow maps. The level-owned elapsed clock freezes on pause and resets on a fresh run; modulation does not accumulate drift or create timers outside the run.

**Alternative:** Fast random flashing, deep darkness, more shadow-casting lights, or renderer-specific volumetrics can be distracting, obscure play, and add unnecessary cost.

### 4. Sparse nonblocking dressing and objective landmarks

Use simple trim/doorframe bands around the existing courtyard/crypt openings and gate, subtle pillar bases/caps within their existing solid footprints, and at most twelve urn instances total (the original four plus up to eight reused copies). Keep the six torches rather than multiplying lights. Place clusters beside walls/outside movement and sight corridors; do not move actors/items or turn noncolliding urns into apparent cover.

Differentiate the courtyard entrance, crypt opening, and sealed exit through material accents, existing warm torch placement, and small, consistent landmark treatments. A flat ground inlay around the key area is allowed on the existing floor, but no new altar obstacle or key mechanic. Retain useful world signs and E interaction feedback; visual improvement is not a reason to remove route information or change interaction range. New detail stays out of the active attack/retreat lanes and does not conceal pickups.

**Alternative:** Filling every empty surface with props, adding fake solid structures, or using a new Meshy kit would increase clutter, cost and gameplay ambiguity. The goal is a restrained finished pass, not a larger map.

### 5. Two bundled ambience loops and an independent session volume

Author original low-level wind and crypt-bed WAV loops offline in Godot, stored separately from the accepted eleven SFX. Use two reusable AudioStreamPlayer instances owned by a new level ambience controller; no per-frame player allocation or ambience requests through the bounded one-shot SFX service. Both loops are local environmental beds, not point emitters that incorrectly reveal room contents through walls. Bundle source/provenance and imported forward-loop metadata; check endpoints/loop boundaries technically and by listening.

Use the existing crypt boundary/doorway to derive a presentation-only blend target. Smoothly transition between wind and crypt emphasis over roughly one second when crossing the doorway, with complementary weights; do not create an Area3D that affects collision, an AI trigger, or a gameplay state change. Mute/gain and blending never alter perception, pickups or combat. Start quietly with headroom; combat warnings, impacts and pickup cues must remain readable at the default mix. Keep levels bounded, use a low fixed ambience gain plus user volume, and verify the combined master output does not clip rather than changing accepted SFX clips/gains.

Add an Ambience bus and a second keyboard/mouse-accessible pause-menu slider, including zero/mute. Preserve the existing SFX slider/value unchanged. The session retains each setting independently across run restarts; no disk persistence is added. Hide both controls where inappropriate and keep the pause panel within the logical 720p/1080p canvas.

Pause freezes ambience blend and playback positions; resume continues without restarting or stacking loops. Defeat/victory, menu return and disposal stop/free the run's loops. A fresh run creates exactly two new players and resets blend/phase, applying the session volume before audible playback. Muting/unmuting changes gain without adding players or replaying a backlog. Only a game-created Ambience bus is removed on session teardown, preserving any preexisting custom bus.

**Alternative:** Reusing the one-shot SFX queue for loops risks voice starvation and pause/replay bugs. One combined volume would disturb accepted combat feedback; hard region switching produces audible boundaries. Downloaded ambience or paid audio generation is outside this proposal.

### 6. Compare stable views and preserve baseline tests before making approval claims

Capture pre-pass entrance/courtyard/crypt/key/exit views with recorded cameras and frozen actors before editing presentation. Add deterministic material/texture-size/provenance checks, collider/placement/navmesh fingerprints, prop/light counts, flicker bounds/pause/reset checks, and ambience stream/count/blend/volume/lifecycle checks. Retain all 196 existing gameplay/model/audio invariants and eight authoring tests, adapting only assertions that intentionally gain presentation nodes.

Render matching post-pass views at 1280×720 and 1920×1080, including enemies/pickups at meaningful ranges, active combat feedback, and both pause sliders. Profile equivalent fixed views on the recorded i3-8100/GTX 1060 machine and compare scene resource counts; do not call a short sample a universal FPS guarantee. If presentation causes a material regression, reduce decorative/texture/light complexity rather than silently changing renderer or gameplay.

Rebuild and test packaged resources from an external working directory and run native startup checks. A person must judge surface tiling, lighting comfort/readability, flicker, ambience seams/transition/default mix, and a complete run/offline result flow. Report missing observations as pending. Existing positive combat feedback does not establish atmosphere approval.

**Alternative:** Headless checks cannot establish good lighting or seamless/comfortable audio, while screenshots alone cannot show unchanged movement/occlusion or lifecycle leaks.

## Risks / Trade-offs

- [Textures show seams, repetition or scale mismatch] → Deterministic tileable source images, shared world-scale mapping and matching-camera seam/scale review.
- [Mood lighting hides enemies or the key] → Ambient floor, restrained contrast, unchanged objective cues, both-resolution combat/route captures and human review.
- [Decoration implies cover or blocks the route visually] → Keep accents within existing solid footprints or wall margins, add no colliders, and verify sight/retreat/key paths plus human play.
- [Flicker is distracting or changes combat visibility] → Smooth ±8% energy bounds, slow deterministic phases, no light toggles/range changes/new shadows, and subjective comfort review.
- [Ambient sound masks accepted cues or clicks at the loop boundary] → Separate conservative bus/volume, complementary smooth blends, loop metadata/end-point tests and listening acceptance.
- [Loops or buses leak through restarts/pause] → Exactly two run-owned players, explicit session transitions/independent volume, teardown ownership and repeated-run tests.
- [Presentation reduces Compatibility performance] → Six lights unchanged, bounded dressing/material/texture counts, standard materials and comparison against the current machine baseline.
- [Multiple active changes blur acceptance ownership] → Keep prior task lists unchanged, reference evidence explicitly and reconcile specs before archiving in dependency order.

## Migration Plan

No save/user data migration is needed. Capture baseline fingerprints/views, author bundled material/loop assets, add presentation behind the developer toggle, then materials, lighting, dressing and ambience in that order. Preserve original flat presentation as a diagnostic fallback and all imported model/SFX sources unchanged. Run regression/render/resource/performance checks, export, then collect visual/listening/playthrough feedback. Do not archive the preceding changes automatically. If canonical specs are promoted in the meantime, reconcile this change's additive contracts before archive.

## Open Questions

- Final darkness, tile scale, decoration density and ambience character/default volume require human approval; the working palette and technical bounds above are implementation-ready.
- Previous detailed/offline acceptance remains unreported. Collect it where possible without interpreting a new visual approval as evidence for old untested flows.
