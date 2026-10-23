CINDERKEEP 0.4.1 - WINDOWS X64 PLAYTEST
====================================

Extract this ZIP to a folder, then launch Cinderkeep.exe.
Keep Cinderkeep.pck beside the executable. No Godot editor, export templates,
.NET, account, installation or network connection is required to play.

CONTROLS
  WASD                 Move
  Mouse                Look
  Space                Jump
  Left mouse (hold)    Attack / repeat after recovery
  1 / 2                Iron Blade / Ember Staff
  E                    Interact with the nearby exit gate
  Escape               Pause / resume
  Tab or arrows        Navigate menus
  Enter or Space       Activate focused menu button

Pause has independent SFX and Ambience volume/mute sliders. Volumes persist
between runs in the current app session, not between app launches.

OBJECTIVE
Leave the safe entrance, cross the courtyard and enter the crypt through
the eastern opening. Collect the gold ember key, then return to the sealed
gate in the courtyard's northeast corner and press E nearby.

Red flasks restore health; blue flasks restore arcana. Full-resource flasks
stay available. The blade costs no mana; you need not defeat every enemy.
Melee has an 80-degree frontal sweep within 2.7 meters, timed to the visible
stroke. A gold hit marker confirms actual damage. Nonlethal hits do not
interrupt committed enemy attacks: use cover, movement or a lethal hit.
Defeat and victory offer restart.

BUILD AND LIMITATIONS
This is the accepted single-level 0.4.1 build: six integrated Meshy models,
photographic stone, moonlit sky, bounded dynamic lights, combat/pickup audio
and environmental ambience. Enemies remain static meshes with whole-model
feedback, not skeletal animation. The separate developer Warden motion study
is NOT included in this ZIP and has not been integrated into gameplay.
No save/load, multiplayer, music, controller support or general settings menu.

The user confirmed the exported build works. Automated package checks and
native headless startup passed; this is not a claim that every hardware,
offline, audio or restart acceptance scenario was manually tested.

Use SHA256SUMS.txt to verify every other bundled file. See CREDITS.txt and
the Godot engine/component notices for attribution and licensing context.
The owner has not selected an overall project redistribution/source license;
this local playtest package is not an announcement of a public release.
