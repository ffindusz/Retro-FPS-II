## Context

The Ossuary ends in the Golem Sanctum: the golem drops the ember key, and the exit gate on the far wall ended the run. The gate was a primitive box. The user wants a generated, impressive door: two stone halves sliding into the walls, a key socket, glowing runes.

## Goals / Non-Goals

**Goals:** a door that reads as the end of the level, opens visibly with the key, and can be placed from the editor like the other kinds.

**Non-Goals:** a second level (walking through still ends the run), changing the demo courtyard gate or the Exit Gate kind, an animated key model.

## Decisions

1. **Three models, not one.** A single generated door cannot slide, so the frame, one leaf and the socket are separate Meshy models. One leaf model serves both halves.
2. **Meshy settings.** Same as the 0.6.2 fixtures: `meshy-t2.5`, smart topology, preview then 2k PBR refine, original text prompts only. The first leaf preview came out as a hollow frame; one replacement preview was made and refined. Total 50 credits.
3. **Glow from the textures.** The frame's texture already paints its runes ember orange, and the socket's keyhole red. `tools/make_rune_masks.gd` turns those colours into 1024 px greyscale emission masks. The materials use them with the *multiply* emission operator, so only the runes glow (the default *add* lit the whole frame).
4. **Leaf runes.** The leaf texture is plain dark granite. The game draws thin emissive strokes over the slab's carved ring and spine, with angular twigs, and brightens the leaf albedo 2.2×. The second leaf shows the slab's back (also carved) rather than a mirrored copy, because negative scale breaks its lighting.
5. **Size.** Frame at 6×: about 4.25 m wide and 5.7 m high, doorway 2.32 × 4.22 m. Leaves 1.2 × 4.3 × 0.36 m, slightly overlapping the pillars and the seam. Socket 1.15 m high, 2.75 m to the right of the doorway and 1.3 m in front, turned a little towards the doorway.
6. **Origin and facing.** The marker is the middle of the threshold; the door's front faces -Z, like the other placements. In the sanctum it is turned 180° to face the room.
7. **Collision.** The frame has box colliders for its pillars and lintel, and the socket has one too. Each leaf is an `AnimatableBody3D` on the world layer, so closed leaves block movement, projectiles and line of sight, and open leaves move out of the way.
8. **States.** Sealed → keyed (1.2 s, runes ramp up) → opening (3.2 s, smoothstep slide by one leaf width) → open. Everything runs in `_process`, so pausing the game freezes it. Restarting rebuilds the level, so the door is sealed again.
9. **Interaction.** `authored_level.interact_exit()` hands E to the door when the level has one. It works within 2.4 m of the socket or 3 m of the doorway, with line of sight (ignoring the socket and the leaves). Without the key it shows a message; with it the key goes in once.
10. **Finishing.** The level finishes when the player is more than 0.8 m past the threshold, inside the doorway's width, after the door is open. It finishes once.
11. **Exit rule.** The builder used to require exactly one Exit Gate. It now requires exactly one exit of either kind, so a level can use the Rune Door instead.
12. **Sanctum wall.** Three ring segments behind the door give way to a straight 0.8 m wall, 6 m high, with a 2.2 m opening (a little narrower than the frame's doorway, hiding the model's rough inner faces). The wall blocks beside the opening are deep enough to hide the open leaves. Behind it, a roofed 4 m corridor with a crystal lamp shows that the way goes on.
13. **Sounds.** No new audio: the key uses the magic-cast cue, the opening uses the charge cue.

## Risks / Trade-offs

- The frame's back is rough generated geometry; it stays hidden only while the door sits in a wall at least 0.8 m thick.
- The leaf runes are drawn by the game, not part of the Meshy texture.
