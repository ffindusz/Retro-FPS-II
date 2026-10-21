## 1. Baseline and confirmed combat events

- [x] 1.1 Record the current 104 gameplay/model checks, eight authoring tests, Windows/render results, stats/placements, and five-minute/easy feedback; check compatibility with the still-active original change and preserve its unverified acceptance tasks.
- [x] 1.2 Make damage handling report actual applied damage while preserving health/death signals; define a small run-owned confirmed combat-event path for attacks, contacts, casts, and player hurt, with no damage applied by feedback consumers.

## 2. Swing-timed melee

- [x] 2.1 Add the authoritative melee phase cycle, attack IDs, hit history, positive configurable timings, held-input repetition, and the default 0.12/0.16/0.24-second timing without changing damage, reach, mana rules, or magic behavior.
- [x] 2.2 Replace the center-only melee ray with a bounded moving frontal sweep using swept/subsampled world queries, per-candidate wall/corner occlusion, and per-target/per-world-contact deduplication.
- [x] 2.3 Drive 3D blade preparation, contact stroke, and return from the same cycle progress; keep the isolated viewmodel viewport and independent world collision.
- [x] 2.4 Defer the latest weapon-selection request until recovery ends; preserve cooldowns, freeze cycle state on pause, and cancel/clear pending work on terminal transitions and fresh runs.
- [x] 2.5 Update instant-melee test assumptions and add windup/recovery exclusion, off-center/multi-target hits, reach/behind-player rejection, walls/corners, large-step phase crossing, switch deferral, and pause/death/restart regression checks.

## 3. Truthful visual feedback

- [x] 3.1 Connect confirmed positive player-caused enemy damage to a brief hit marker and local enemy reaction; ensure misses, walls, rejected damage, dead targets, and HUD refreshes produce no false confirmation or shared-material changes.
- [x] 3.2 Add distinct enemy/world impact effects and non-obscuring player-damage edge feedback, with at most 24 live world effects and at most 0.5-second active lifetimes; avoid camera shake, FOV changes, and time scaling.
- [x] 3.3 Make feedback pause/terminal/disposal behavior run-owned and explicit; verify repeated sessions leave no stale markers, effect nodes, actor references, or subscriptions.
- [x] 3.4 Add automated event/lifetime/cap checks and render 720p/1080p views of actual contact, misses, wall strikes, independent enemy reactions, incoming damage, and readable HUD feedback.

## 4. Original combat audio

- [x] 4.1 Author deterministic local SFX generation and bundle the required swing, enemy-hit, wall, magic/projectile, enemy windup/cast, and player-hurt cues; record provenance and verify nonempty, unclipped resources without paid services or runtime generation.
- [x] 4.2 Add a run-owned SFX service, conservative bus gain/limiting, local player cues, spatial enemy/world cues, and a 12-voice cap that drops presentation instead of queuing bursts.
- [x] 4.3 Connect deduplicated combat events, stop/discard one-shots on pause/terminal/menu transitions, and clean up voices across repeated runs without replaying stale audio on resume.
- [x] 4.4 Add an accessible SFX volume/mute slider to the pause menu; retain it across runs for the app session and ensure adjustment neither attacks nor resumes gameplay.
- [x] 4.5 Add headless resource/event/voice/mute/cleanup checks and rendered mouse/keyboard focus checks for the slider; clearly separate these technical passes from subjective listening acceptance.
- [x] 4.6 Add distinct locally authored health/arcana pickup cues after successful positive restoration only; preserve accepted combat WAVs, verify deduplication/capped gain/full/paused/dead/muted behavior and no false hit feedback, update provenance/playtest notes, and rebuild/recheck the Windows package.

## 5. Encounter pressure without health inflation

- [x] 5.1 Preserve enemy ATTACK state, remaining windup, and cooldown progression on nonlethal hits while allowing hit feedback; verify repeated hits cannot suppress attacks indefinitely, cover remains effective, and lethal hits still cancel pending attacks once.
- [x] 5.2 Reposition existing courtyard/crypt enemies and, only where justified, existing pickups for mixed melee/ranged pressure; record before/after placements while preserving safe entry, cover, actor counts, stats, geometry, and objective rules.
- [x] 5.3 Verify unchanged four-melee/two-ranged and three-health/three-mana counts, navigation/retreat routes, key/exit progression, zero-mana viability, and fresh-run reset with the revised placements.

## 6. Validation and delivery

- [x] 6.1 Run the full adapted regression suite and authoring tests, complete both-resolution render checks, and record a short post-polish performance sample with effect/voice limits and existing model/texture budgets intact.
- [x] 6.2 Rebuild the Windows export, run packaged-resource regression and native startup smoke checks, and verify bundled SFX/models resolve without authoring tools, credentials, or runtime downloads.
- [ ] 6.3 Complete and record a human listening pass for cue distinction, synchronization, spatial readability, default mix comfort, and mute/volume behavior; leave pending if no listening review is available.
- [ ] 6.4 Complete and record a human revised-demo playthrough for melee clarity, difficulty, duration, cover/zero-mana progression, pause/resume, defeat/victory/restart/menu flows, and an offline native-build run; compare against the five-minute/easy baseline without claiming untested outcomes.
- [x] 6.5 Update controls, audio provenance, design/tuning notes, validation results, and known limitations; report remaining human checks honestly and reconcile both active changes before any separate archive action.
