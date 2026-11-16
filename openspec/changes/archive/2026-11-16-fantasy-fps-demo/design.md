## Context

At proposal time the workspace contained OpenSpec scaffolding and Godot 4.7 stable Windows executables, but no game project or existing specs. The demo is an original, single-player fantasy FPS inspired by Hexen II's low-detail geometry, dark stone environments, and physical-looking first-person weapons. All gameplay is GDScript; the HUD is 2D and weapons, enemies, and the environment are 3D.

Meshy.ai authors models outside the game, via manual exports or an explicitly authorized local API authoring tool. The initial implementation assumed no credentials, generated models, animation rigs, or export templates; the user subsequently supplied local credentials and authorized the six-model generation batch. The game remains playable using placeholders, while final demo acceptance includes a representative Meshy.ai asset integration pass.

## Goals / Non-Goals

**Goals:**
- A complete start → explore/fight → collect key → reach exit → victory loop in one level.
- Responsive keyboard/mouse controls and legible melee/projectile combat.
- Two weapons, two enemy archetypes, health/mana pickups, and a small reusable scene architecture.
- Original, low-detail dark-fantasy presentation with a dependable model replacement workflow.
- An offline Windows build plus clear setup, controls, asset provenance, and verification instructions.

**Non-Goals:**
- Multiplayer, multiple levels, classes, skill trees, equipment inventory, persistence, or a custom boss.
- Recreating Hexen II layouts, names, characters, sounds, or other protected assets.
- Runtime Meshy.ai API integration, procedural world generation, a general-purpose model-generation product, or a full animation pipeline. A small opt-in developer authoring script is allowed by the user's generation follow-up.
- Advanced renderer effects, a configurable graphics menu, controller support, and broad platform certification.

## Decisions

### 1. Godot 4.7, Compatibility renderer, and a root-level project

Use the available Godot version, typed GDScript where practical, the Compatibility renderer, and Godot's built-in primitives, physics, navigation, UI, and resource system. Keep `project.godot` at the workspace root; separate `scenes/`, `scripts/`, `resources/`, `assets/`, `tests/`, and `docs/`. Do not track generated `.godot/` caches, export binaries, or credentials.

Suggested scene boundaries:
- `scenes/main.tscn`: session flow and UI ownership.
- `scenes/player/player.tscn`: `CharacterBody3D`, collider, look pivot, world camera, weapon controller.
- `scenes/weapons/`: reusable melee/magic definitions and 3D viewmodels.
- `scenes/enemies/`: shared enemy base plus melee/ranged variants.
- `scenes/levels/demo_level.tscn`: blockout, navigation, encounters, pickups, and exit.
- `scenes/ui/`: `Control` scenes presented through a `CanvasLayer`.

**Alternative:** Forward+ and external frameworks offer more features but add hardware requirements and dependencies without benefiting this demo.

### 2. Explicit session states and scene-owned run state

A session controller owns `MENU`, `PLAYING`, `PAUSED`, `DEFEAT`, and `VICTORY` transitions. A fresh level instance owns its enemies, pickups, key flag, and exit. Restart destroys the old run and creates a fresh player and level; no save state is retained. Level signals report objective completion, and player signals report health/resource changes and death. UI observes signals rather than directly changing combat internals.

Pause uses `SceneTree.paused`; gameplay nodes are pausable and menu controls continue processing. Pausing releases the mouse, freezes gameplay timers/physics/projectiles, and suppresses attacks. Losing application focus during gameplay also enters pause and requires explicit resume. Death and victory disable gameplay input and freeze the run immediately. Keyboard focus and mouse input must both work in menus.

**Alternative:** A large global singleton is quicker initially but makes restart leakage and coupling harder to test. Global run state is unnecessary for one level.

### 3. Simple first-person movement and layer-separated 3D weapons

Use `CharacterBody3D.move_and_slide()` with gravity, floor-only jumping, normalized planar movement, clamped pitch, and yaw on the player root. Default actions are WASD movement, mouse look, Space jump, left mouse attack, 1/2 weapon selection, E interact, and Escape pause. Keep sensitivity as an exported tuning value; a settings screen is not required.

Render real 3D weapon meshes with a transparent, isolated `SubViewport` and weapon camera composited below the HUD. It shares the main viewport's aspect/size but not world geometry, preventing walls from clipping the weapon. Only presentation lives there; aiming, collision, and damage use the world camera and world physics. A center-screen world ray chooses the aim point. Projectiles spawn at a collision-safe world position near the player; an obstruction check prevents shots crossing nearby walls. Viewmodel meshes have no gameplay collision.

**Alternative:** Weapon sprites violate the 3D weapon constraint; world-camera-only weapons can intersect walls. A separate viewport costs an extra rendering pass but is a bounded trade-off for two low-detail viewmodels.

### 4. Bounded combat rules and reusable enemy behavior

The melee weapon has a short-range world-space query, a cooldown, no mana cost, and at most one damage event per target per attack. The magic weapon launches a visible 3D projectile, consumes mana only on a successful shot, and rejects fire when empty or on cooldown. Weapon switching cannot reset cooldowns. Export damage, range, speed, costs, and health for tuning rather than hard-coding them in scene flow.

Use a small shared damage interface (`take_damage(amount, source)`) and explicit collision layers/masks for world, player, enemies, projectiles, and pickups. Projectiles use swept collision between physics positions, stop at the first blocking surface, ignore their owner, and expire after a bounded lifetime. Player shots cannot damage the player; enemy attacks cannot damage other enemies in this demo. Dead actors cannot attack or receive repeated death rewards/events.

Enemies use a minimal idle/chase/attack/dead state machine, `NavigationAgent3D`, a baked navigation region, and line-of-sight tests. Melee enemies close distance; ranged enemies approach to firing range and telegraph projectile attacks. Both stop attacks when dead and cannot hit through walls. Static Meshy meshes can use transform-based bob, recoil, flashes, and death feedback; skeletal animation is not a dependency.

**Alternative:** A general ability framework, behavior trees, or mandatory rigged animation would overbuild the demo. Pure direct-line movement would fail around level corners.

### 5. One authored, greybox-first fortress level

Build three connected spaces: a safe entrance that introduces controls, a courtyard with combat and a visible locked exit, and a crypt containing the key and mixed encounter. Return routing avoids long backtracking. Use static, simple collision independent of decoration and bake navigation after layout changes. No platforming precision, moving platforms, or physics puzzles are required.

The exit requires the key and a nearby E interaction, not elimination of every enemy. A locked interaction explains the objective. Collecting the key updates the HUD; reaching the unlocked exit ends the run exactly once. Health and mana pickups apply capped gains and are consumed only when useful. The melee weapon always remains usable so depleted mana cannot soft-lock progression.

**Alternative:** A boss or multiple puzzle gates adds content and tuning risk without being necessary to prove the core loop. A 5–10 minute first playthrough is a playtest target, not a timed gate.

### 6. External Meshy.ai pipeline with stable asset wrappers

Build gameplay against wrapper scenes with separate visual roots and authored collision. First use Godot primitive placeholders; then import Meshy models as glTF/GLB with included textures. Normalize models to meters, ground or grip pivots, and Godot-facing orientation within the wrapper, preserving gameplay transforms. Keep viewmodel and world-model transforms independent.

Maintain `docs/asset-manifest.md` with asset IDs, purpose, local paths, Meshy source/export identifiers when available, prompt/source notes, attribution/license status, import settings, and placeholder/final status. Never invent licensing or generation claims. A short prompt/model checklist covers the two weapons, two enemy silhouettes, and a small set of fortress props. Modular floors and walls can remain authored Godot geometry.

Initial budgets are approximately 5,000 triangles per prop or weapon, 10,000 per enemy, and at most 1024-pixel textures unless measured results justify exceptions. These are content targets, not unsupported hardware performance guarantees. Remove unwanted geometry and use simple colliders; do not require generated meshes to produce accurate physics. Representative imported weapons, enemy visuals, and props are required before calling the Meshy art integration complete; otherwise explicitly label the build a placeholder prototype.

**Alternative:** Runtime downloads or direct imported-scene gameplay scripts make offline builds, reproducibility, and later reimports fragile.

The 2026-10-20 follow-up authorizes one generated variant each of the cleaver, staff, warden, adept, torch, and urn. Use Meshy T2.5 Smart Topology with bounded face counts and a separate 2K texturing pass: documented estimated cost 90 credits for the batch. `tools/meshy_generate.py` reads a local environment variable or ignored `.env`, checkpoints paid task IDs, and resumes those tasks without automatically replacing failed/uncertain submissions. Credentials and signed URLs are never recorded. Keep downloads outside the project in the approved local staging directory until distribution rights are reviewed. No API code or credentials enter the Godot runtime/export. Source textures may be 2K because that is the API's minimum; the later import pass must limit runtime textures to 1024 or document an exception.

### 7. Test core rules automatically and presentation manually

Use lightweight GDScript headless tests without a new test framework for health/resource bounds, weapon cooldown/damage rules, projectile collision, objective state, pause, and fresh-run reset. Add a headless main-scene smoke check after import. Keep a documented manual checklist for mouse capture, movement feel, readable 2D HUD, actual 3D viewmodels, enemy telegraphs, wall occlusion, resize/aspect handling, and a complete win/lose/restart loop.

Create a Windows export preset and use matching Godot export templates. Validate the exported build offline, including imported materials and scene/resource paths. Record editor version, tested machine and resolution, asset status, and known limitations. Missing templates or user-supplied Meshy models are reported as blockers to the relevant deliverable, not silently treated as passed.

**Alternative:** Only manual testing makes repeated state/collision regressions easy to miss; only headless tests cannot judge FPS feel or rendering.

## Risks / Trade-offs

- [Generated meshes have inconsistent topology, scale, pivots, or licenses] → Use visual wrappers, simple authored collision, budgets, provenance records, and human review before distribution.
- [Final models or Meshy access are unavailable] → Keep every mechanic playable with clearly labeled placeholders; leave final-art tasks incomplete until assets are supplied.
- [Static enemy meshes look stiff] → Design readable silhouettes and procedural attack/death feedback; revisit rigging only after the demo is fun.
- [Extra viewport, lighting, and navigation cost performance] → Use modest geometry, restrained lights, short sightlines, and profile the actual test machine before adding visual effects.
- [Projectiles tunnel or originate through walls] → Sweep each physics step, check spawn obstruction, and test point-blank and high-speed shots.
- [Restart or pause leaves live callbacks/input behind] → Own entities under the run scene, gate terminal transitions, and test repeated state changes.
- [A retro reference grows into an oversized remake] → Enforce the one-level/two-weapon/two-enemy content cap and use original content.

## Migration Plan

No existing application or data needs migration. Establish the Godot project, build a complete placeholder loop, then replace visuals without changing gameplay interfaces. Package only after editor and exported-build acceptance checks. Keep placeholder wrapper variants available if an imported model breaks rendering; preserve original source exports rather than overwriting them during cleanup.

## Open Questions

- Confirm or revise the proposed fortress/crypt theme and the default melee-plus-magic loadout before significant art work. They are working defaults, not implementation blockers.
- Resolved during implementation: the user supplied a local API key, explicitly authorized the six-model batch, and confirmed a paid monthly subscription. The batch cost 90 credits; its generation-specific rights review, source hashes, import transforms, and remaining public-release caveats are recorded in the asset documents. No broader regeneration budget is assumed.
- What reference PC should define the eventual frame-rate target? Until selected, record measured results rather than promise a hardware-independent target.
