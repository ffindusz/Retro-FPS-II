## Why

Build a small, playable fantasy FPS to validate the feel of retro first-person exploration and combat before committing to a larger game. A single original level inspired by Hexen II's dark-fantasy atmosphere keeps the demo achievable while proving the Godot and Meshy.ai asset workflow.

## What Changes

- Create a desktop, single-player Godot 4 project with gameplay written in GDScript.
- Add first-person mouse-look, movement, jumping, collision, health, and death/restart behavior.
- Add two 3D first-person weapons: a melee weapon and a projectile-firing magic weapon with a finite, replenishable resource.
- Add two simple 3D enemy archetypes, melee and ranged, with readable attacks, damage, and death.
- Build one compact ruined-fortress level, targeting a first playthrough of roughly 5–10 minutes, with exploration, combat, pickups, a key, and a locked exit.
- Add a 2D HUD, start/pause screens, and defeat/victory flows.
- Define a Meshy.ai-to-Godot model pipeline, using original low-detail models and playable placeholders until final assets are available. Support manual exports or explicitly authorized, credit-bounded API authoring outside the game.
- Deliver a runnable project and a validated Windows demo export with setup and controls documented.

## Capabilities

### New Capabilities

- `first-person-player`: Movement, camera control, collision, player health, and input capture.
- `fantasy-combat`: 3D weapon presentation, melee/projectile combat, resources, and two enemy behaviors.
- `single-level-demo`: One complete level with encounters, pickups, a key/exit objective, and repeatable run state.
- `game-interface`: 2D gameplay HUD, menus, pause, defeat, victory, and restart flows.
- `model-asset-pipeline`: Reproducible Godot setup, Meshy.ai model import conventions, placeholder substitution, and demo packaging.

### Modified Capabilities

None. This is a new project with no existing capability specifications.

## Impact

- Introduces `project.godot`, Godot scenes, GDScript scripts, input actions, resources, imported assets, and export configuration.
- Uses the available Godot 4.7 stable editor as the initial toolchain; targets Windows desktop using the Compatibility renderer.
- Meshy.ai is an external authoring tool, not a runtime service. The user can supply exports or authorize local API generation with their own key; the game must run without an account, API key, or network connection.
- Adds asset provenance/license records and manual acceptance checks. Godot export templates are an external packaging prerequisite.
- Does not include multiplayer, additional levels, character classes, inventory/equipment systems, save/load, a custom boss, or copied Hexen II content.
