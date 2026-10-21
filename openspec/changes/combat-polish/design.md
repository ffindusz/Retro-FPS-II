## Context

The implemented Godot 4.7 demo has six imported Meshy models, two weapons, six enemies (four melee/two ranged), three health and three mana pickups, a key, and an exit. The user reported a roughly five-minute, easy playthrough using both weapons. Existing validation has 104 gameplay/model checks, eight authoring-tool tests, rendered checks, and a Windows export.

Melee currently applies damage immediately through one camera ray; the 0.3-second viewmodel pulse is presentation-only. Enemies visibly lean during windup, but `take_damage()` unconditionally returns a living enemy to CHASE, allowing rapid player hits to cancel successive attacks. Combat is silent and lacks explicit hit confirmation. Physics, imported-model wrappers, pause ownership, and run teardown already work and should be preserved.

`fantasy-fps-demo` remains active with two human acceptance tasks open. This follow-up depends on its implemented code, does not archive it, and must not claim those checks complete. Because the canonical spec registry is empty, four additive polish capabilities describe the new behavior without editing the original change's specifications.

## Goals / Non-Goals

**Goals:**
- Make the first weapon's visible contact and actual damage understandable without explaining a hidden crosshair ray.
- Distinguish enemy hits, walls, misses, casts, and incoming damage through consistent visual/audio events.
- Keep modest encounter pressure, cover, and readable windups without increasing health pools or adding content.
- Reuse all six models, stay offline at runtime, preserve short sessions, and make regression checks deterministic.

**Non-Goals:**
- Skeletal rigs, paid generation/animation/audio services, new models, weapons, enemies, levels, or paid API calls.
- Rigid-body sword simulation, a general ability/event framework, squad AI, knockback/stagger mechanics, or a difficulty selector.
- Music, ambient soundscape, a complete settings screen, environment retexturing, camera shake, hit-stop, or FOV kicks.
- Treating one easy five-minute run as proof of final balance or completed offline acceptance.

## Decisions

### 1. A single authoritative melee cycle drives both damage and the 3D animation

Give the weapon controller explicit READY/WINDUP/ACTIVE/RECOVERY phases, a monotonically increasing attack ID, elapsed time, and a per-attack set of damaged target IDs. Initial tuning is 0.12s windup, 0.16s contact, and 0.24s recovery: the existing 0.52s repeat interval remains. Preserve range 2.7m and damage 34, and expose phase durations and arc width for tuning. Holding attack repeats only after recovery.

The viewmodel consumes the controller's normalized phase progress to show draw-back, a right-to-left strike, and return. Replace the independent melee pulse timer; keep magic's presentation separate. World collision remains independent of the isolated overlay mesh, but the authored contact phase and sweep progression share the same clock as the visible stroke. No damage is applied on initial button press or during recovery.

Queue the latest weapon-selection request during a committed melee cycle and apply it at recovery end; do not reset either weapon's cooldown. Death, victory, run disposal, and menu return disable/cancel pending work; restart starts READY with empty hit history. Pause freezes phase progress, sweep state, and animation; resume continues that state without replaying missed time. Prefer physics-driven state over deferred timers that can survive a run.

**Alternative:** Enlarging the old ray is cheap but keeps the misleading instant hit. Rigid-body blade collision in the overlay cannot correctly query the world and adds unnecessary simulation.

### 2. Sweep a bounded frontal volume, validate occlusion, and deduplicate contacts

Use small sphere/capsule queries across an authored frontal arc, initially about 80 degrees, centered near the camera/chest plane. Advance sample positions from the previous contact progress to the current progress on physics ticks, including the whole crossed contact interval if a frame spans a phase boundary. Swept segments/subsamples prevent gaps at low frame rates. Query current world transforms, not a target captured at button press.

Bound each accepted target by the configured reach and frontal envelope at contact; query thickness must not extend the permitted reach or allow hits behind the player. Validate each candidate's contact path against World collision and reject occluded candidates, including targets behind nearby corners. Emit at most one applied-damage contact per target and one blocking-world feedback contact per swing. More than one exposed enemy can be struck once each in the same arc; nothing is damaged just because the decorative blade overlaps it onscreen.

Keep World/Player/Enemy layers and projectile swept collision unchanged. A small reusable melee query helper is acceptable; no external physics dependency is needed.

**Alternative:** A one-time cone overlap is easier but does not track a moving visible sweep and easily hits through pillars. Unbounded area collision risks striking behind the player or repeatedly damaging a target.

### 3. Publish confirmed combat results, not guesses from animation or input

Have actor damage handling report the actual applied amount (zero for dead/inactive/invalid targets), retaining existing health/death signals. The weapon/projectile path reports a small, run-owned combat event: attack ID when applicable, source/target, world point/normal, contact kind, applied amount, and lethal flag. The run routes this to the HUD, effect spawner, and audio service. Feedback does not apply damage itself, hold dead actor references, or become a global persistent event bus.

An actual player-caused enemy damage event shows a brief crosshair hit marker (initially 0.12s). Local bounded sparks/magic impact flashes distinguish world strikes from enemy hits; a miss produces only swing/cast presentation. Enemy hit reactions remain visual and do not reset the attack state. Incoming positive damage gives a brief, low-opacity screen-edge flash; never obscure the crosshair or health display. Reuse model/material overlays or temporary per-instance visuals without rewriting shared imported materials. No head movement, time scaling, or camera shake is added.

Expire effects after at most 0.5s and cap live world impact instances (initially 24). Paused gameplay freezes their lifetimes; terminal transitions clear transient feedback and run disposal owns cleanup. Tests must confirm invalid/duplicate contacts never produce a successful-hit marker or repeated lethal feedback.

**Alternative:** Deriving a marker from an attack animation or a non-null ray result produces false confirmation for misses, walls, and already dead targets. A global signal singleton makes old-run callbacks easier to leak.

### 4. Bundle original SFX and route them through a small bounded SFX service

Author short synthetic/noise/envelope-based WAV clips locally with a deterministic Godot authoring script. Bundle the outputs; the game does not need Python, a generator, account access, or a network connection. Record authoring source, parameters, and provenance in the asset manifest. Review clips with actual playback: they should be usable effects, not loud test tones. External licensed replacements are future work, not an implicit download or paid-service authorization.

Required cue families: melee whoosh, enemy-hit impact, wall clang, player magic cast, projectile/world impact, enemy melee windup, enemy ranged cast/windup, and player hurt. Reuse variants where appropriate, but keep swing/hit and player/enemy casts recognizable. Player attacks/hurt are local non-positional cues; enemy and world-contact cues use `AudioStreamPlayer3D` with bounded range and the gameplay camera as listener. Event IDs/contact deduplication prevent the same swing or impact sounding once per query/frame.

Use one run-owned service and an SFX bus with conservative defaults, a built-in limiter, and at most 12 concurrent voices. Author source clips below full scale without clipping. Finished voices release their nodes; overload drops the oldest low-priority impact, never queues a burst. Stop active one-shots and discard pending cues on pause/terminal/menu transitions; resume never replays them. This deliberately favors clean transitions over resuming a half-finished whoosh. Reset tears down all audio nodes.

Add one keyboard/mouse-accessible SFX slider in the existing pause menu, including zero/mute. Retain its value for the app session and across run restarts; disk persistence and a full settings screen are out of scope. HUD/state/volume updates must not trigger sounds. Muting does not alter gameplay or remove visual tells.

The 2026-10-21 follow-up adds two original local player cues: a warm health chime and a brighter arcana chime. Emit each only after its pickup successfully restores a positive amount, with a pickup-specific event ID and the actual capped restoration amount. Full-resource, already consumed, paused/dead-player, enemy, and invalid-amount attempts stay silent; the key remains unchanged. Reuse the existing SFX service/volume/cleanup rather than attaching audio players to pickups that are immediately freed. Author only the two new WAVs so the user's accepted combat sounds remain unchanged. Existing combat audio, melee and difficulty received positive user feedback; detailed control/offline checks and listening to the new cues are not inferred from that feedback.

**Alternative:** Runtime synthesis and free-running audio timers complicate pause/test determinism. Third-party sounds introduce rights work; paid services would exceed this proposal's authorization. One unconstrained player per impact can create unpleasant clipping during a cleaving attack.

### 5. Tune existing encounters and preserve enemy attack commitments

Change nonlethal enemy damage so IDLE can alert into CHASE and CHASE stays CHASE, but ATTACK retains its current windup and cooldown. A hit reaction is not an implicit stagger. At windup completion, recheck range/line of sight as before; lethal damage still cancels the pending attack immediately. Do not shorten telegraphs or let enemies damage through cover.

Keep the existing four melee/two ranged enemies, three health/three mana pickups, player health/mana, weapon damage/costs, and enemy health/damage. Reposition the courtyard and crypt packs so melee pressure and a readable ranged firing lane can overlap after the player deliberately enters combat. Keep entrance/spawn safe, maintain cover and retreat space, and move existing pickups only if that creates a clearer risk/reward choice. Do not add random spawns, reinforcements, kill-all gates, offscreen unavoidable attacks, or new collision geometry.

Document before/after placements and the reason for each change. The five-minute/easy run is the baseline; target a more engaging roughly 5–10 minute run, not guaranteed deaths or a fixed numerical difficulty increase. Confirm zero-mana progression and the key/exit loop remain possible.

**Alternative:** Raising health makes fights longer without making decisions more interesting. New AI systems or more actors would enlarge the demo and make the cause of balance changes harder to isolate.

### 6. Preserve existing coverage while adding contact, feedback, and audio checks

Update old instant-melee assertions to drive the authoritative cycle explicitly. Keep all existing collision/cooldown/resource/ownership/model/pause/restart invariants; add off-center arc hits, windup/recovery misses, occluded corner cases, multiple queries/targets, phase-boundary/large-step behavior, switch deferral, death cancellation, and repeated runs.

Use event/audio counters or a test sink for headless checks; dummy audio cannot establish sound quality. Render contact-phase, impact, enemy-reaction, damage-flash, mute/slider, and both-resolution HUD views. A human listening/playthrough pass must check cue distinction and comfortable levels, input/animation alignment, difficulty, run length, and an offline native-export win/lose/restart loop. Record blockers or untested subjective checks instead of marking them passed from automation.

**Alternative:** Relying only on screenshots hides silent/misaligned sound or a delayed damage bug; relying only on headless checks cannot prove readable motion or a comfortable mix.

## Risks / Trade-offs

- [Melee volume feels too generous or hits around cover] → Keep reach unchanged, restrict the frontal envelope, validate world occlusion, and test edges/corners and off-center targets.
- [Physics timing and animation drift] → Use one phase clock; sweep every crossed contact interval and test small/large time steps against the same contacts.
- [Reliable windups abruptly increase difficulty] → Preserve health/damage/telegraph durations, change placements modestly, and require a new playtest before claiming balance success.
- [Static models remain visually stiff] → Use clear procedural strokes/lean/reactions; do not promise skeletal animation or spend rigging credits in this change.
- [Synthetic SFX are unpleasant or repetitive] → Conservative levels, short varied cues, voice limits, a mute/volume control, and a human listening gate.
- [New effects/audio leak across pause or restart] → Run ownership, bounded lifetimes/voices, explicit transition cleanup, and repeated-session tests.
- [Two active changes have overlapping acceptance work] → Keep separate task lists and evidence; do not archive/complete the original change automatically. Archive in dependency order when both are actually ready.

## Migration Plan

No persistent game data requires migration. Record current test/export/playtest baselines, implement the melee cycle and event path first, then visual/audio consumers, then encounter tuning. Retain original Meshy files and model wrappers unchanged. Rebuild the Windows export after regression checks; do not replace missing human listening/playtest evidence with an automated pass. Before archiving, reconcile against any specs promoted from `fantasy-fps-demo` in the meantime so the polish contracts remain additive and consistent.

## Open Questions

- Subjective sound character, final mix levels, and whether the new attack/encounters feel sufficiently clear and engaging require the user's playtest. Initial technical defaults above are implementation-ready.
- The prior change's remaining acceptance checks are still open; obtain those observations without inferring them from the earlier successful run.
