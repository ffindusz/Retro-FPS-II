## 1. Model

- [x] 1.1 Survey the supplied golem GLB: clips, hammer, facing, size, eyes; pick the slam timing.
  - 2026-11-24: clips idle 1.67 s, walk 1.04 s, attack 1.83 s, death 2.5 s; no run or hit clip; faces +Z; about 2.2 m tall; hammer on `Prop_Hammer`; no eyes (a `headfront` bone exists). Slam contact at 1.55 s.
- [x] 1.2 Keep the golem's `source/` folder out of import and export (`.gdignore`).
- [x] 1.3 Golem presentation (dormant statue, awakening, eyes, dust rings, body tint) on top of the skeleton presentation.

## 2. Gameplay

- [x] 2.1 Golem enemy: dormant/wake rules, melee range, slam, held key, boss group.
- [x] 2.2 Boss health bar in the HUD.
- [x] 2.3 Bone seal from the key ward, with its own messages.
- [x] 2.4 Golem statue prop derived from the golem model.
- [x] 2.5 Placement kinds 16–18 with previews, builder overlap check and runtime spawning.
- [x] 2.6 Golem Sanctum in The Ossuary (`level_factory`, `tools/create_ossuary.gd -- --replace`); key and exit moved.
  - The first version used 0.15 m steps up to the pedestal. The player could not climb them (found by the test), so the pedestal is now a sloped round block.

## 3. Verification and handoff

- [x] 3.1 Add golem tests and run `tools/verify.ps1`.
  - 2026-11-24: `tests/test_golem_boss.gd` 38 checks. `tests/test_skeletons.gd` updated for the moved exit and the extra enemy. Full `tools/verify.ps1` passes with 0 failures. Real-editor `--test-level-editor`: 42 checks, 0 failures (all nineteen palette buttons). Python tests not run (no Python on this machine).
- [x] 3.2 Render the sanctum; bump to 0.11.0; update README and asset manifest.
  - `tools/capture_sanctum.gd` renders the closed seal, the room, the dormant and awake golem, statues, windup, slam, boss bar and the revealed key to `builds/validation/sanctum/`.
- [x] 3.3 Get the user's playtest of the Golem Sanctum. Record only what is reported.
  - 2026-11-24: the user reported "works".
