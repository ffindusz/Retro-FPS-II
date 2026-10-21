## 1. Godot project foundation

- [x] 1.1 Create the root Godot 4.7 GDScript project with the Compatibility renderer, main scene, folder structure, and cache/build/credential ignore rules.
- [x] 1.2 Configure named input actions for movement, look, jump, attack, weapon slots, interact, and pause; define documented physics layers and masks.
- [x] 1.3 Add a minimal session controller and disposable run scene with explicit menu, playing, paused, defeat, and victory states.
- [x] 1.4 Verify a headless import and main-scene smoke launch without missing resources; document the local editor invocation.

## 2. Player and first-person presentation

- [x] 2.1 Build the player scene with CharacterBody3D collision, normalized yaw-relative movement, gravity, and grounded-only jumping; verify against a temporary test floor and wall.
- [x] 2.2 Implement bounded mouse-look, gameplay-only cursor capture, pause on focus loss, and input suppression outside active gameplay.
- [x] 2.3 Add bounded player health, healing, damage signals, and a one-shot death event; verify lethal damage prevents movement and interaction.
- [x] 2.4 Create the isolated 3D weapon viewport/camera and two placeholder weapon viewmodels; verify wall proximity and resize behavior at both test resolutions.

## 3. Weapons and damage rules

- [x] 3.1 Add shared damage handling and exported combat tuning values; define owner/team exclusions for attacks and projectiles.
- [x] 3.2 Implement 1/2 weapon selection and the melee attack's range, wall occlusion, cooldown, single-hit-per-target rule, and visible swing feedback.
- [x] 3.3 Implement bounded mana, magic firing cost/cooldown, empty-mana feedback signals, and world-camera aiming independent of viewmodel transforms.
- [x] 3.4 Build visible world projectiles with spawn obstruction checks, swept collision, first-impact resolution, owner/team filtering, and lifetime cleanup.
- [x] 3.5 Verify weapon switching cannot bypass cooldowns and blocked/point-blank/high-speed shots cannot damage through walls.

## 4. Enemy behavior

- [x] 4.1 Create a shared enemy scene/script with health, idle/chase/attack/dead states, visual-root separation, and NavigationAgent3D movement.
- [x] 4.2 Add the melee enemy with detection, path pursuit, visible attack windup, range/line-of-sight checks at attack resolution, and cooldowns.
- [x] 4.3 Add the ranged enemy with approach-to-range behavior, visible windup, line-of-sight checks, and damaging projectiles.
- [x] 4.4 Add readable hit/death feedback, cancel pending attacks on death, and remove dead enemy blocking; verify both archetypes navigate around test cover.

## 5. Complete single-level gameplay loop

- [x] 5.1 Author the original entrance/courtyard/crypt greybox, safe spawn, static collision, identifiable exit, and baked navigation with a viable return route.
- [x] 5.2 Place bounded encounters using both enemy types and verify the route remains completable without clearing every enemy or using mana.
- [x] 5.3 Add health/mana pickups that apply capped gains once, remain when not useful, and reject inactive players and enemies.
- [x] 5.4 Add the collectible key and nearby, line-of-sight E exit interaction with locked feedback, objective signals, and single-fire victory.
- [x] 5.5 Implement fresh-run creation and teardown; verify repeated restart restores all actors, resources, key/exit state, and weapon selection without stale projectiles or events.

## 6. 2D HUD and menus

- [x] 6.1 Build the CanvasLayer HUD with crosshair, current/max health and mana, weapon selection, key status, interaction/objective messages, and insufficient-mana feedback.
- [x] 6.2 Add a start screen with Start, Quit, and the full controls legend; support mouse and keyboard menu activation.
- [x] 6.3 Add pause/resume/restart/quit-to-menu controls; freeze gameplay timers and entities while keeping menus responsive and prevent resume clicks from firing.
- [x] 6.4 Add distinct defeat/victory screens, freeze terminal gameplay state, release the cursor, and verify restart and return-to-menu flows.
- [x] 6.5 Verify HUD, viewmodels, and menus at 1280×720 and 1920×1080, including resize, focus loss, and keyboard focus navigation.

## 7. Meshy.ai asset workflow and art integration

- [x] 7.1 Document original-art direction, model prompts/checklist, GLB import steps, triangle/texture targets, scale/orientation/pivots, materials, and collision separation.
- [x] 7.2 Create an asset manifest for all bundled visuals with source paths/identifiers, provenance, license status, import settings, and placeholder/final status.
- [x] 7.3 Generate explicitly user-authorized Meshy.ai models or obtain user-supplied exports for both weapons, both enemy archetypes, and at least two props; verify distribution rights before bundling. Leave this task blocked if assets or rights are unavailable.
- [x] 7.4 Import and normalize supplied models in visual wrapper scenes; preserve authored collision and scripts, record settings, and retain usable placeholder alternatives.
- [x] 7.5 Review imported models in combat and exploration, including both 3D weapon viewmodels, enemy silhouettes/telegraphs, material appearance, and prop placement; report unresolved art explicitly.
- [x] 7.6 Apply a restrained original dark-fantasy material/lighting pass and profile the demo on the recorded test machine before increasing visual complexity.

## 8. Verification and Windows delivery

- [x] 8.1 Add and run headless GDScript checks for health/mana bounds, melee range/occlusion/single hits, cooldown persistence across weapon switches, firing costs, projectile collision/expiry, and enemy death cancellation.
- [x] 8.2 Add and run integration checks for useful-only pickups, key/exit gating, pause/timer freezing, terminal state guards, and repeated fresh-run reset without duplicate actors/events.
- [ ] 8.3 Complete and record an editor playthrough checklist covering movement, mouse capture, navigation, both weapons/enemies, zero-mana progression, key/exit, pause, victory, defeat, restart, and menu return; tune toward a 5–10 minute first run.
- [x] 8.4 Add the Windows desktop export preset and matching-template setup instructions; produce a build if prerequisites are available and otherwise record the packaging blocker.
- [ ] 8.5 Validate the Windows export offline through a complete win/lose/restart loop, inspect imported resources and input/HUD behavior, and record tested hardware, resolution, editor version, and observed performance.
- [x] 8.6 Finish README/setup/controls/test/export instructions, credits, asset status, and known limitations; distinguish a playable placeholder prototype from the completed Meshy-integrated demo and leave unverified acceptance tasks unchecked.
