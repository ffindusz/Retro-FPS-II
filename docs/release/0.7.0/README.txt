CINDERKEEP 0.7.0 - EDITOR WORKFLOW POLISH PLAYTEST
===============================================

Launch Cinderkeep.exe with Cinderkeep.pck beside it. No editor, addons,
templates, .NET, account or runtime network is needed to play.
Start selects the original/default demo; Choose Level discovers public
built maps. Mapping Example remains a direct shortcut to The Mason's Trial.
Restart retains the selected map and resets health, mana, key and actors.

CONTROLS
  WASD / mouse       Move / look
  Space              Jump
  Left mouse (hold)  Attack / repeat after recovery
  1 / 2              Iron Blade / Ember Staff
  E                  Interact with nearby exit gate
  Escape             Pause / resume; Back from Choose Level
  Tab / arrows       Navigate menus
  Enter or Space     Activate focused menu button
Pause offers independent SFX and Ambience sliders.

MAPPING EXAMPLE
Cross the courtyard, enter the eastern crypt room, collect the ember key,
then return to the courtyard's northwest gate and press E nearby.
Red/blue pickups restore health/arcana; full-resource pickups stay available.
Nonlethal hits do not cancel committed enemy attacks. Melee costs no mana.

EDITOR CHANGES (requires the source project, not this EXE)
Arm a Cinderkeep palette kind, then click a valid floor/wall. A transient
preview follows the pointer; R rotates, Esc/RMB cancels. Undo/redo remains.
Validation issues select their source objects. Build records source/resource
fingerprints; new built public maps appear in Choose Level automatically.
Use Checked Export PCK in the editor or tools/export_checked.ps1 to block
stale/missing maps and refuse existing outputs. Stock Godot export only
warns and bypasses this gate. Full guide: docs/editor-workflow-polish.md.

LIMITATIONS / REVIEW
Designer ergonomics and the new map/menu/export controls need user review.
Navigation checks do not certify every jump, doorway or encounter.
Existing animation/foot-planting/finger/pose limits remain. One start, ember
key and exit; no campaign progression or arbitrary external mod loading.
No save/load, multiplayer, music, controller support or general settings menu.
Automated checks and native startup/menu rendering pass; a full explicitly
disconnected interactive native run is not claimed. Older handoffs are intact.

See CREDITS.txt, GODOT-LICENSE.txt, GODOT-COPYRIGHT.txt and SHA256SUMS.txt.
No new Meshy credits were spent on this workflow milestone. This local
playtest handoff is not public-release clearance or a project-wide license.
