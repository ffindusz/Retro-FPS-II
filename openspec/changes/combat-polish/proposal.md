## Why

The user completed the demo with both weapons in roughly five minutes and found it easy, but had to ask how the first weapon hits: the current instant crosshair ray does not match the visible blade swing. Improve combat clarity and responsiveness before adding more content, while keeping the successful short demo loop intact.

## What Changes

- Replace instant, needle-thin melee hits with a short frontal sweep during an explicit windup/contact/recovery cycle, synchronized with the 3D blade animation.
- Add clear enemy-hit confirmation, local impact effects, readable enemy hit reactions, and restrained player-damage feedback. Misses and wall strikes must not look like successful enemy hits.
- Add original, locally authored combat sounds for swings, impacts, player magic, enemy windups/casts, and player damage; provide a small SFX volume control in the pause menu.
- Follow-up requested on 2026-10-21: add distinct health and arcana pickup cues, emitted only after useful restoration and routed through the same volume/mute control.
- Increase encounter pressure modestly through mixed-enemy placement and reliable enemy attack commitments rather than increasing enemy health. Preserve attack telegraphs, cover, and a safe entrance.
- Keep one level, two weapons, the six existing Meshy models, health/mana limits, the key/exit objective, and the roughly 5–10 minute target. Do not require additional Meshy generations or paid services.
- Extend headless/rendered checks and rebuild the Windows demo, with human timing/difficulty and offline acceptance results recorded honestly.

## Capabilities

### New Capabilities

- `swing-melee`: A phase-driven frontal melee sweep, animation/contact synchronization, target deduplication, and attack lifecycle rules.
- `combat-feedback`: Truthful hit confirmation, bounded world impacts, enemy reactions, and non-obscuring player-damage feedback.
- `combat-audio`: Original bundled SFX, event-driven playback, bounded/spatial mixing, pause/restart behavior, and volume control.
- `encounter-tuning`: Bounded pressure tuning using the existing enemies/resources, uninterrupted nonlethal windups, and a recorded playtest baseline.

### Modified Capabilities

None in the canonical spec registry: `openspec/specs/` is currently empty because `fantasy-fps-demo` is implemented but not yet archived. The new capability specs add polish contracts on top of that change's existing requirements, rather than silently editing its pending acceptance tasks.

## Impact

- Builds on the implemented `fantasy-fps-demo` working tree; that change remains active at 37/39 tasks, with human acceptance tasks 8.3 and 8.5 still pending.
- Main touchpoints: `scripts/weapons/weapon_controller.gd`, `scripts/weapons/viewmodels.gd`, `scripts/weapons/projectile.gd`, `scripts/enemies/enemy.gd`, `scripts/player.gd`, `scripts/level.gd`, `scripts/session.gd`, and `scripts/ui/interface.gd` plus their scenes.
- Introduces a small combat-event/feedback path, bundled original audio, an SFX bus, and lightweight effect scenes. Uses existing Godot/GDScript tooling and tests; no runtime network, plugins, new models, rigging service, or API credentials are required.
- Melee damage becomes delayed until contact; weapon switching during a swing is deferred until recovery. Existing tests that assume instant damage must be updated without losing wall/cooldown/pause/restart coverage.
- Does not include another level, more enemy types or weapons, skeletal animation, complex squad AI, inventory progression, music/ambient soundscape, a general settings screen, or a full environment-art pass.
