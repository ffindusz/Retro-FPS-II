## Why

On 2026-11-24 the user supplied a stone golem model (`assets/models/stone_golem/`, Meshy sources rigged and animated in Blender) and asked for it as a boss in The Ossuary: a new round room that opens once every skeleton is dead, with the golem standing like a statue on a pedestal in the middle. It attacks when the player comes near, reveals the key when it dies, and has a boss health bar. The room is decorated with lamps and smaller golem-like statues (generated with Meshy or derived from the golem model). Once the key is taken, the door to the next level (to be decided) can be opened.

## What Changes

- New **Stone Golem** boss enemy built from the supplied model. It starts dormant: frozen in place, eyes dark, untouched by the AI. It wakes when the player comes within range with a clear line of sight, or when it is hit. Waking takes a short moment (shake, dust, eyes light up), then it walks at the player and slams its hammer down in a telegraphed two-handed strike.
- Boss health bar at the top of the HUD while the golem is awake.
- The golem holds the level's ember key: the key stays hidden until the golem dies, then appears where it fell.
- **Bone Seal**: a ward that blocks a doorway until every other enemy in the level has died. It reuses the existing key ward with its own messages.
- **Golem Statue**: a decorative statue on a plinth, derived from the golem model (smaller, weathered, posed). No Meshy generation is used.
- New placement kinds `Bone Seal` (16), `Stone Golem` (17) and `Golem Statue` (18), appended, with editor previews and builder checks.
- The Ossuary gains the round **Golem Sanctum** north of the gallery: a stepped dais in the middle, four statues, braziers and wall lanterns. The ember key moves from the side chamber to the golem, and the exit gate moves to the sanctum's far wall as the door to the next level. The next level is not decided yet, so using the gate still ends the run with the existing victory screen.
- `enemy.gd` gets a configurable melee range (default unchanged at 1.9 m).
- Tests and version 0.11.0.

## Capabilities

### New Capabilities

- `golem-boss`: the stone golem boss, its dormant/awake behaviour and key, the boss health bar, the bone seal, golem statues and the Golem Sanctum in The Ossuary.

### Modified Capabilities

None at the requirement level. The Ossuary layout changes (key and exit positions); existing enemies keep their behaviour.

## Impact

New golem enemy, model and statue scenes and scripts, `skeleton_presentation.gd` (model hook and scale), `enemy.gd` (melee range), `key_ward.gd` (configurable messages), `level_placement.gd`, `authored_level.gd`, the level builder and factory, `tools/create_ossuary.gd`, the Ossuary authoring and generated scenes, the HUD, tests, docs and version. No paid generation.
