## Decisions

1. **Shared, opt-in.** The stagger lives in `enemy.gd` (timing, attack cancel, guard) and `skeleton_presentation.gd` (the clip), and is switched on per enemy scene with `stagger_on_hit`. The golem, warrior and archer turn it on; the Warden, Adept and bat do not.
2. **Clip.** The presentation maps a `Hit` role to the GLB's `hit` clip and samples it like the other clips, with the same 0.15 s blend in and out and no horizontal root drift. The small flinch tilt is not added on top of it.
3. **Stagger time.** The enemy stays staggered for the clip's length (1.67 s for all three): no movement, no attack, no turning. Without a hit clip, a 0.8 s fallback is used.
4. **Interrupting attacks.** A stagger during a windup cancels the attack: no damage, no arrow, and the enemy goes back to chasing. Its attack cooldown is unchanged.
5. **Guard.** After a stagger ends, hits do not stagger again for 4 s (`stagger_cooldown`). Hits during a stagger do not restart it. Without the guard, magic at 0.36 s per bolt would keep an enemy staggered for good.
6. **Golem waking.** The hit that wakes the statue, and hits during the 1.6 s awakening, do not stagger, so the awakening plays out.
7. **Pause.** The stagger counts down in `_physics_process` and stops while the player cannot act.
8. **Sound.** No new audio: the golem's `golem_stagger` uses the stone `wall` cue on top of the usual hit sound; the skeletons use only the hit sound.
9. **Golem crumble (2026-11-26).** The new death clip is played like the old one and holds its last frame. The rubble chunks are scaled to zero in every other clip, so the living golem and the statues show no rubble. All skinned surfaces get their own tinted material copy. The culling box grows to 2.6 m model radius (3.5 m in the world) to hold the scattered chunks. The key waits 2 s instead of 1 s so it appears on the settled pile.
