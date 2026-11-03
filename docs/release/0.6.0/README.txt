CINDERKEEP 0.6.0 - VISUAL LEVEL AUTHORING PLAYTEST
================================================

Launch Cinderkeep.exe with Cinderkeep.pck beside it. No Godot editor,
addons, templates, .NET, account or runtime network is required to play.
Start plays the preserved original demo. Mapping Example plays the new
Cyclops-authored entrance/courtyard/crypt map, The Mason's Trial.

CONTROLS
  WASD / mouse       Move / look
  Space              Jump
  Left mouse (hold)  Attack / repeat after recovery
  1 / 2              Iron Blade / Ember Staff
  E                  Interact with the nearby exit gate
  Escape             Pause / resume
  Tab or arrows      Navigate menus
  Enter or Space     Activate focused menu button

Pause has independent SFX/Ambience volume sliders. Defeat/victory offer
restart of the selected level, with fresh health/mana/key/enemies.

EXAMPLE OBJECTIVE
Cross the courtyard, enter the eastern crypt room, collect the gold ember
key, then return to the gate at the courtyard's northwest side and press E.
Red/blue pickups restore health/arcana; full-resource pickups stay available.
Melee costs no mana. Nonlethal hits do not cancel committed enemy windups.

MAKING MAPS
The source project (not this EXE) includes pinned Cyclops 1.5.2 and a
Cinderkeep Godot editor dock: New Level, gameplay placements, Build,
Check and Playtest. Source example: scenes/authoring/mapping_example.tscn.
Use the dock's Playtest Level, not F6 on the source. Build before export.
See docs/level-authoring.md in the project for the complete no-code guide.

KNOWN LIMITS / REVIEW
First milestone supports static Cyclops architecture and one player start,
one ember key and one exit. No random generator or in-game editor.
Navigation/clearance checks do not certify every jump/stair/encounter.
Existing open fingers, foot sliding and some pose intersections remain.
No save/load, multiplayer, music, controller support or general settings menu.
Automated source/editor/package tests and native startup/menu rendering
pass; designer ergonomics and interactive/offline native-map review remain.
Accepted 0.4.1/0.5.0 artifacts remain separate and unchanged.

See CREDITS.txt, GODOT-LICENSE.txt, GODOT-COPYRIGHT.txt and SHA256SUMS.txt.
This local validation handoff is not a public release or a project-wide
source/distribution license grant. No additional Meshy credits were spent.
