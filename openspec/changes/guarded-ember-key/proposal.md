## Why

In the 0.5.0 playtest the user suggested placing the ember key behind a barrier guarded by enemies. In the 0.7.0 playtest the run felt right but the key is simply lying in the open crypt corner, so collecting it needs no fight. On 2026-11-16 the user asked for the barrier with guarding enemies.

## What Changes

- Enclose the key in a small walled alcove in the crypt's northeast corner, entered through one 2 m gateway.
- Close the gateway with an arcane ward: iron bars with ember glow that block the player, enemies and projectiles.
- Station three key guards in front of the ward: the two existing crypt-corner enemies (the melee one moved out of the new wall) plus one new Warden. Total enemies rise from 6 to 7.
- When the last guard dies, the ward stops colliding, sinks into the floor and shows "The ward lifts. The ember key is free." Approaching the closed ward explains how to open it.
- Re-bake the demo navigation, re-record the gameplay baseline deliberately, update tests and docs, and bump the version to 0.8.0.

## Capabilities

### New Capabilities

- `guarded-ember-key`: walled key alcove, ward lifecycle tied to its guards, hints, pause and restart behaviour.

### Modified Capabilities

None. Player, weapon and enemy stats and the gate/victory rules are unchanged.

## Impact

`scripts/level.gd`, a new `scripts/props/key_ward.gd`, `resources/demo_navigation.tres`, `resources/atmosphere_baseline.tres`, gameplay tests, README and version. The authored mapping example is unchanged. No new art generation, paid services or new audio.
