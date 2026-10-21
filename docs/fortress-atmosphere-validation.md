# Fortress atmosphere validation

## Baseline captured before presentation changes — 2026-10-21

- Combat-polish 0.2.1: **196 gameplay/model/audio checks pass**, **8 authoring tests pass**.
- Source hashes for six original Meshy GLBs, eleven accepted SFX WAVs and the original navigation resource are recorded in `docs/fortress-atmosphere-baseline.json`.
- Canonical collider/gameplay-placement/stat/navigation snapshots are recorded in that JSON and in `resources/atmosphere_baseline.tres`. No prior acceptance task was changed.
- Six fixed camera views (entrance, courtyard, crypt, key, exit and close stone surface), each at 1280×720 and 1920×1080, are under `builds/validation/atmosphere/before/`.
- Frozen-actor, fixed-courtyard, vsync-off 2s comparison sample on the recorded i3-8100/GTX 1060 PC: 1280×720 mean 1.324ms (755.45 observed frames/s), 220 draw calls; 1920×1080 mean 1.383ms (722.89 observed frames/s), 222 calls. Raw data is `before/profile.json`. This is a short comparison sample, not a minimum-FPS or whole-run claim.

## Implementation / new acceptance

The technical atmosphere pass is implemented as **0.3**. Human visual/flicker comfort, new ambience/mix, gameplay-duration and offline acceptance remain open; earlier positive combat feedback is not reused as approval of this presentation. No paid generation/API call or external texture/audio asset download was used.

### Preserved gameplay and accepted sources

- All 196 original gameplay/model/audio invariants remain covered. The expanded suite passes **233 source and packaged checks**; all **11 offline asset/tool tests** pass.
- Canonical fingerprints match the pre-change baseline for all **22 static colliders**, six enemy placements/stats, three health/three arcana/key placements, player/weapon tuning, spawn/exit, and navigation data. The original navigation file hash is unchanged; the nav authoring helper is tested without a player or ambience and without saving a new navmesh.
- All six original GLB and eleven SFX WAV hashes match the recorded originals. Model normalization/import limits and isolated weapon-view lighting are unchanged. New presentation has **zero collision objects**.
- The developer atmosphere toggle is default on. The disabled path restores the old flat/static world and no ambience while matching the same gameplay snapshot. Prior changes' acceptance task states were left untouched.

### Presentation and asset review

- Three original stone families use six 512×512 albedo/roughness images with mipmaps/repeat and world-aligned triplanar mapping, approximately two meters per image tile. **Eleven cached world material variants** (shared family/area materials and solid iron/brass accents) avoid per-block allocation. Source seeds/patterns and import details are in `assets/environment/README.md`.
- Ambient light has a .42 energy visibility floor, cooler moonlight and six warmer torch pools. Torch base energy is 2.0 with deterministic 1.1/.37Hz components clamped to ±8%; light locations, range 7, non-shadowed torch behavior and the existing directional shadow source remain unchanged. Pause/reset checks cover the lighting clock. The player weapon viewport's .85 ambient energy is unchanged.
- **Ten urn instances** reuse the existing model (four original plus six wall-margin additions), with **six torches**, shallow doorway/pillar accents, gate bands and a flat key-floor inlay. No room, roof, collider, cover, objective or gameplay placement was added/changed. Thin accents do not cast duplicate shadows over existing solids; original world/urn shadows remain.
- Fixed after views are at `builds/validation/atmosphere/after/`, matching the six original camera poses at both resolutions. Reviewed surface scale/tiling, warm/cool differentiation, route/key cues and absence of blacked-out routes in these controlled captures. Existing frozen enemies can occlude parts of key/exit views; their positions were not moved to manufacture a clearer comparison.
- Existing combat render checks also pass with atmosphere enabled, including marker/impact/damage presentation, pause/results and **both independent sliders** within the 720p/1080p canvas. Synthetic keyboard/mouse tests verify independent input without gameplay leakage. Headless pointer tests explicitly supply the window mouse-enter notification missing from the dummy display driver; no OS cursor warping or desktop capture is used.

### Ambience and lifecycle

- Two original **20-second mono 22,050Hz PCM16** loops are bundled, with imported forward-loop metadata, uncompressed/no-normalization settings and source peaks at most .25. A .75s overlap join is technically checked for ordinary boundary sample continuity. Construction/seeds are in `assets/audio/ambience/README.md`; technical continuity is not subjective seamlessness approval.
- Exactly **two run-owned reusable players** blend complementary wind/crypt weights at one unit per second across the existing crypt boundary. They do not use the SFX voice pool, trigger gameplay events, or alter accepted SFX gain/resources.
- Default Ambience user volume is **30%**, independently retained across runs; the fixed bus gain is .15. At full user volume the bounded source mix is about .0375 peak amplitude before Master, leaving headroom below the accepted SFX limiter's -1dB ceiling. Default mix comfort and cue masking still require listening.
- Pause freezes blend and playback; tests allow the last backend mix buffer to settle before reading paused playheads. Resume continues without another start. Defeat/victory/menu/disposal stop and detach streams; repeated runs keep only two current players. Muting ambience leaves combat/pickup SFX audible. Only game-created buses are removed on session teardown.

### Technical comparison and delivery

Reference: same Windows 10 / i3-8100 / GTX 1060 6GB, Godot 4.7 Compatibility/OpenGL, frozen enemy/player physics and fixed courtyard camera, deterministic after-light clock, vsync off, about two seconds per resolution. These are short view samples, not controlled whole-run benchmarks or universal FPS guarantees.

| Resolution | Before mean ms | After mean ms | Observed delta | Before/after draw calls | After observed frames/s |
|---|---:|---:|---:|---|---:|
| 1280×720 | 1.324 | 1.533 | +.209ms (~16%) | 220 / 244 | 652.47 |
| 1920×1080 | 1.383 | 1.484 | +.101ms (~7%) | 222 / 244 | 673.92 |

After primitive counts are 101,880 / 141,720 respectively; resolution-dependent LODs contribute to the difference. Early decorative shadow passes raised calls to about 282; disabling redundant thin-band shadows reduced them to 244. The remaining measured absolute view cost is below .22ms on this reference sample, so no renderer change or gameplay reduction was made. Normal gameplay, other hardware and worst-case combat still need testing.

- Source regression: **233 checks, 0 failures**. Offline asset/tool tests: **11 pass**, including unchanged accepted hashes, six-image budget/imports and two bounded distinct loop resources/boundaries.
- The Windows export at `builds/windows/Cinderkeep.exe` + `Cinderkeep.pck` was rebuilt. The **233-check packaged-resource suite passes from an external temporary working directory**, including bundled material/loop resources, gameplay fingerprints, fallback and two-slider lifecycle behavior. It does not rely on project-local authoring outputs at runtime.
- Native Windows startup smoke exits **0**. Strict OpenSpec validation passes. No source/packaged/render pass is a claim of human visual/listening approval or a full disconnected native run.
- Technical logs are `atmosphere-*.log` under `builds/validation/`, with comparison profiles/images under `atmosphere/{before,after}/`. The baseline JSON and Resource snapshot are retained; after capture cannot overwrite the original before baseline.

## Pending human acceptance

- [ ] Visual review: stone scale/tiling/seams, lighting/flicker comfort, readable enemies/resources/objectives, uncluttered routes and improved fortress identity.
- [ ] Listen while moving between courtyard and crypt: loop seams, transition, default mix under casts/impacts/pickups, independent volume/mute, pause/resume and clean result/menu/restart behavior.
- [ ] Complete a run and report timing/difficulty, zero-mana/cover viability, and an offline native win/lose/restart check with tested resolution/hardware.

These observations gate tasks 6.4/6.5. Source assets, controls and game rules remain unchanged, but presentation readability and ambience quality are deliberately left for user feedback. There is no new music, volumetric fog, renderer upgrade, skeletal animation or content expansion. Original generator textures/audio are intentionally simple and are not claimed as photoreal stone scans or professionally mastered ambience.
