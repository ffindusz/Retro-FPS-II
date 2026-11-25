## Why

On 2026-11-25 the user asked Meshy to generate "an impressive door for the exit of the level": a large stone door whose two sides slide into the walls, with a socket to insert the key found in the level, glowing with runic carvings. Until now The Ossuary's exit was a plain primitive gate in the Golem Sanctum.

## What Changes

- Three new Meshy models (text-to-3D, refined with PBR textures): a carved stone door frame with ember-orange runes, a solid stone door leaf (used for both halves) and a key socket pedestal with a red keyhole. Prompts and the credit record are in `docs/meshy-rune-door.json`; 50 credits were used.
- `tools/meshy_generate.ps1`: a PowerShell port of the Meshy tool, because Python is not installed on this machine.
- **Rune Door** prop (`scenes/props/rune_door.tscn`): the frame, two sliding leaves with collision and glowing rune strokes, and the key socket in front of the right-hand pillar. The runes glow through emission masks baked from the Meshy textures (`tools/make_rune_masks.gd`).
- Behaviour: the door starts sealed with softly pulsing runes. Interacting without the key explains what the socket needs. With the key, the key appears in the socket, the runes blaze, and after a moment both leaves slide sideways into the walls. Walking through the open doorway finishes the level. The next level is still not decided, so finishing shows the existing victory screen.
- New placement kind `Rune Door` (19), appended, with an editor preview. A level needs exactly one exit: an Exit Gate or a Rune Door.
- The Ossuary: the Golem Sanctum's far wall becomes a straight facade with the rune door set into it, and a short lit corridor behind it. The sanctum's gate lamps move aside for the socket.
- Tests and version 0.12.0.

## Capabilities

### New Capabilities

- `rune-door`: the sliding rune door exit, its key socket and its placement kind.

### Modified Capabilities

None at the requirement level. The Golem Sanctum's exit changes from the Exit Gate to the Rune Door; the golem, seal and key are unchanged.

## Impact

New models under `assets/models/rune-door-frame`, `rune-door-leaf` and `rune-key-socket`; `scripts/props/rune_door.gd` and its scene; `level_placement.gd`, `authored_level.gd`, the level builder (exit rule) and factory; the Ossuary authoring and generated scenes; `combat_audio.gd` (two cues); tests, docs and version. Paid generation: 50 Meshy credits.
