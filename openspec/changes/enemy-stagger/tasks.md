## 1. Stagger

- [x] 1.1 Map the `Hit` clip for the golem, warrior and archer; add `stagger()` to the skeleton presentation (the golem skips it while dormant or waking).
- [x] 1.2 Shared stagger in `enemy.gd`: opt-in `stagger_on_hit`, stagger time from the clip, attack cancelled, 4 s guard; golem waking rule; `golem_stagger` sound cue.

## 2. Verification and handoff

- [x] 2.1 Stagger checks in `tests/test_golem_boss.gd` and `tests/test_skeletons.gd`; run `tools/verify.ps1`.
- [x] 2.2 Render the staggers (`tools/capture_sanctum.gd`, `tools/capture_ossuary.gd`); bump to 0.12.1; update README and asset manifest.
- [x] 2.3 Golem crumble: tint all skinned surfaces, widen the culling box, key after 2 s; rubble checks in `tests/test_golem_boss.gd`; render the crumble.
- [x] 2.4 Get the user's playtest of the staggers and the golem crumble. Record only what is reported.
  - 2026-11-26: the user played it: "feels good and works".
