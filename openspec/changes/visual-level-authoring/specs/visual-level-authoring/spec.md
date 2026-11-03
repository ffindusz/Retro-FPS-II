## ADDED Requirements

### Requirement: Visual level construction
The project SHALL provide a tested pinned Cyclops integration and a reusable authored level template within Godot, without running editor services in the shipped game.

#### Scenario: Construct a map
- **WHEN** a designer creates a level and edits its blocks/materials
- **THEN** the source SHALL remain editable and geometry SHALL support collision and per-level navigation after build

### Requirement: No-code gameplay placement
Designers SHALL place player start, Warden, Adept, health, mana, ember key, exit, torch, urn and ambience zone through a palette with visible previews, editable properties and undo/redo. Editing SHALL NOT start combat/audio or persist preview duplicates.

#### Scenario: Place and reopen objects
- **WHEN** placements are added, moved, duplicated, undone/redone and saved/reopened
- **THEN** intended data SHALL persist once and preview-only descendants SHALL not become runtime actors

### Requirement: Non-destructive build and validation
Build SHALL create independent ordinary runtime geometry, placement data and navigation from the authored source. Required-object, supported-geometry, clearance and navigation failures SHALL block a successful build; stale output SHALL be reported. Existing unrelated outputs and designer source content SHALL not be overwritten.

#### Scenario: Rebuild after changing architecture
- **WHEN** a valid source level is rebuilt
- **THEN** its associated runtime output SHALL update while source blocks and hand placements remain unchanged

#### Scenario: Invalid map
- **WHEN** start/key/exit is missing, a required placement is obstructed or disconnected, or output belongs to another source
- **THEN** the tool SHALL report the problem rather than silently play an invalid or unrelated map

### Requirement: Full-session playtest and selection
The selected authored level SHALL run with existing combat/HUD/audio/pause/defeat/victory/restart behaviour. Restart SHALL recreate the same selected level. The original demo SHALL remain selectable and retain its gameplay fingerprints.

#### Scenario: Playtest authored level
- **WHEN** the designer chooses Playtest Level or the player chooses the built example
- **THEN** the normal session SHALL load that level and restart it cleanly without duplicate actors or leaked state

### Requirement: Portable validated example
A complete small authored example SHALL include connected entrance/courtyard/crypt areas, enemies, supplies, one ember key and an exit, plus a separate versioned Windows validation build. Editor addons/source scenes/credentials SHALL not be required by the exported game; original accepted sources/builds SHALL remain unchanged.

#### Scenario: External packaged validation
- **WHEN** the exported PCK is tested outside the project working directory
- **THEN** both the original demo and new authored map SHALL load and pass their gameplay checks without prototype/editor-resource fallback
