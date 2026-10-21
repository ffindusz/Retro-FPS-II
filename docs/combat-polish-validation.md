# Combat polish validation

## Pre-change baseline — 2026-10-20

- Godot 4.7 stable, Compatibility renderer, Windows 10 / i3-8100 / GTX 1060 6GB.
- Re-ran the source import/smoke/regression suite: **104 checks, 0 failures**. Python authoring/GLB checks: **8 tests pass**. Existing native export startup, packaged-resource checks and 720p/1080p rendered checks are recorded in `docs/validation.md`.
- User-reported baseline: played through with both weapons, reached the exit in roughly **5 minutes**, difficulty **easy**; melee's crosshair-only contact was unclear.
- Original change remains active at 37/39 tasks. Its human/offline acceptance checks are not completed or archived by this follow-up.
- Stats to retain: player 100 health / 60 mana; melee 34 damage / 2.7m reach / 0.52s cycle; magic 28 damage / 5 mana / 0.36s cooldown; melee/ranged enemy health 68/56, damage 12, windups 0.55/0.8s, cooldowns 1.6/2.0s.

### Original placement baseline (x, y, z)

| Kind | Positions |
|---|---|
| Melee | (-6, .1, -4), (6, .1, -3), (19, .1, -10), (28, .1, -5) |
| Ranged | (-7, .1, -11), (26, .1, -11) |
| Health | (-2, .5, 8), (-10, .5, -9), (28, .5, -2) |
| Mana | (2, .5, 8), (8, .5, -10), (17, .5, -3) |
| Key | (28, .5, -12) |

## Post-change evidence

The technical implementation is complete for combat-polish **0.2**. The expanded headless regression suite passes **178 checks**, including the retained baseline invariants. No new human listening, difficulty, timing, or offline native-playthrough outcome is asserted. No paid generation/API calls were made. The original `fantasy-fps-demo` acceptance tasks remain unchanged.

### Revised placements and pressure rationale

| Kind | Revised positions | Rationale |
|---|---|---|
| Courtyard melee | (-9, .1, -10.5), (10, .1, -10) | Two exposed flanks converge around existing pillar cover instead of presenting a single close target; outside initial spawn detection. |
| Courtyard ranged | (-6, .1, -12) | Rear firing lane overlaps approaching melee, while the existing left health pickup requires a cover/retreat decision. |
| Crypt melee | (18, .1, -4), (25, .1, -10) | One readable door-side threat and one deeper threat around existing cover. |
| Crypt ranged | (29, .1, -8) | A visible back-room lane reinforces the existing mixed encounter without another enemy or reinforcements. |
| All pickups and key | Unchanged from baseline | Preserve resource availability and avoid stacking multiple simultaneous difficulty changes. |

Actor counts, health/damage/resources, windup lengths, collision geometry, navigation resource, and key/exit rules remain unchanged. Automated checks confirm safe idle spawn, six enemies, three health/three mana pickups, connected key/return paths, and original stats. Nonlethal hits now preserve committed enemy windups; lethal hits and cover still prevent invalid damage. A fresh human run is needed to judge how much harder this feels.

## Implemented behavior and technical evidence

- Melee uses .12s windup, .16s active sweep, and .24s recovery. An 80° frontal capsule sweep is subsampled at no more than 2° intervals; first-contact rays enforce world/corner occlusion, 2.7m reach, and frontal bounds. Each target can receive 34 damage at most once per attack. Magic damage/cost/cooldown are unchanged.
- The same controller clock drives the blade pose and deferred weapon selection. Render review caught the original overlay camera sharing the animated root; the camera/light now remain outside that root, and tests verify camera transforms stay fixed while the weapon moves.
- Actor damage methods return actual applied damage. Confirmed events contain IDs/values, not actor references; the owning run routes them to bounded effects, the HUD, and audio. A gold hit marker represents actual player-caused enemy damage; misses, walls, duplicate events, and invalid targets cannot claim hits. Incoming damage uses an edge-only flash, at most about .18 opacity, without camera shake or time scaling.
- World impact visuals are original radial shards, at most 24 live instances with .32s lifetimes. Recent event IDs are deduplicated within a bounded 256-entry window; producers also track per-attack contacts and resolved projectiles.
- Nine original mono PCM16 WAVs are bundled. Tests verify distinct nonempty waveforms, source/imported peaks at or below 0.5, no import normalization/compression, and correct event counts. The SFX service has conservative voice/bus gain, a -1 dB ceiling limiter, finite-range spatial world/enemy cues, and at most 12 voices; overload drops presentation rather than queuing it.
- Pause stops one-shots without replaying them, while melee/effect state freezes. Terminal/menu transitions clear transient presentation. Volume/mute persists across runs within the app session. Real keyboard/mouse event tests cover the pause slider and gameplay input isolation.
- Source regression: **178 checks, 0 failures**; three consecutive verbose runs also pass without ObjectDB/resource shutdown warnings. Stopped streams are detached before voice disposal, and test shutdown allows .2s for the backend audio buffer to drain. Runtime voice/node cleanup has separate immediate assertions.
- Original Python authoring/GLB-inspection tests: **8 pass**. They do not make API requests.
- Rendered 1280×720/1920×1080 checks: pass. Reviewed preparation/contact poses, actual off-center hit confirmation, wall-only impact, independent enemy reactions, restrained incoming-damage edges, pause slider bounds/focus, and result screens. These controlled scenes and screenshots are not a human gameplay/listening pass.
- Windows release rebuilt at `builds/windows/Cinderkeep.exe` + `Cinderkeep.pck`. Packaged resources pass **178 checks** using the matching editor runtime from an external temporary working directory, without falling back to project-local resources. This checks the nine bundled sounds, six models and imported texture limits as well as combat behavior. Native release startup smoke exits 0 with empty stderr; a full interactive offline native run is still pending.
- The export excludes `.env`/credentials, authoring tools, tests, docs, and validation output. No runtime network request, local model generation, or authoring-tool installation is needed to play.

Latest technical artifacts are under `builds/validation/`: `combat-tests.log`, `combat-repeat-*.log`, `combat-render.log`, `combat-export.log`, `combat-packaged-tests.log`, `export-smoke.*.log`, and rendered PNGs. Key new images include `melee-windup-1280.png`, `melee-swing-1280.png`, `melee-wall-impact-1280.png`, `damage-feedback-1280.png`, and `pause-volume-1280.png`.

## Short performance sample

Same recorded PC/renderer as the baseline, 30 warmup frames and roughly 3s per fixed courtyard view, vsync disabled, active enemies and SFX enabled, player health refreshed to keep the sample active:

| Resolution | Mean frame ms | Observed frames/s | Longest frame ms | Draw calls / primitives | Peak effects / voices |
|---|---:|---:|---:|---|---|
| 1280×720 | 1.61 | 620.21 | 6.21 | 181 / 84,674 | 0 / 0 |
| 1920×1080 | 1.47 | 680.64 | 5.66 | 180 / 91,954 | 0 / 1 |

Engine-drawn frame counts match the sample counts (1,861 and 2,042). Raw latest output is `builds/validation/profile.json`. This short moving-encounter sample did not stress effects/voice limits; those are saturated in dedicated automated checks. It is not a full-run benchmark, a controlled before/after performance comparison, or a minimum-frame-rate guarantee.

## Pending human acceptance

### User feedback and pickup follow-up — 2026-10-21

- The user reported: "sounds are ok, mellee is better, difficulty ok". Record this as positive general listening, melee clarity, and difficulty feedback for the existing combat-polish build. No new duration, mute/spatial-control observations, or offline/restart coverage were supplied.
- The user requested health/arcana pickup audio. Version **0.2.1** adds two distinct local chimes through the existing SFX bus, using actual capped restoration amounts and pickup-specific event IDs. Full-resource, consumed, zero-gain, enemy, paused/dead, and muted attempts do not play a pickup sound. Successful muted restoration still works; pickups never produce a combat hit marker/effect. Key audio is unchanged.
- Original nine combat WAVs were hash-checked unchanged. Only the two new files were authored, with no paid API calls. All eleven cues meet the same mono PCM16/headroom/import checks. The user subsequently confirmed "sound works" for the pickup-audio follow-up on 2026-10-21.
- Expanded source regression: **196 checks pass**, including sixteen pickup-specific behavior checks and two additional waveform checks. Existing 178-check results, render/performance numbers, and listening limitations above remain historical evidence for 0.2; they are not relabeled as new performance measurements.
- Windows 0.2.1 export rebuilt. The full **196-check packaged-resource suite also passes from an external temporary working directory**; native startup exits 0, the existing eight authoring-tool tests pass, and strict OpenSpec validation passes. Follow-up logs are `pickup-import.log`, `pickup-tests.log`, `pickup-export.log`, `pickup-packaged-tests.log`, and `pickup-smoke.*.log` under `builds/validation/`.
- Task 4.6 is complete, with user confirmation that pickup sound works. Tasks 6.3/6.4 remain partially evidenced, not fully checked off: acknowledge the positive sound/melee/difficulty feedback without claiming unreported detailed control, timing, or offline/restart tests passed.

- [ ] Listen during actual combat: distinguish swing/miss, enemy hit, wall clang, player cast, enemy warning/release, and incoming damage; judge synchronization, distance cues, default volume comfort, mute and slider behavior.
- [ ] Play a revised run: judge melee clarity and pressure, record duration/difficulty, check cover and zero-mana progression, and exercise pause/resume plus defeat/victory/restart/menu flows.
- [ ] Launch the native Windows build offline and exercise a complete win/lose/restart loop, reporting tested resolution/hardware and any missing sounds/resources.

These observations gate combat-polish tasks 6.3 and 6.4. Technical completion, audible device playback during a render harness, and the earlier five-minute/easy run are not substitutes. Synthetic sound quality and the balance effect of reliable enemy windups remain subjective limitations until reviewed. Source assets and model normalization are unchanged; no skeletal animation, ambient/music pass, camera shake, or new content is included.
