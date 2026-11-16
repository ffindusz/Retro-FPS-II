## ADDED Requirements

### Requirement: Deliberate surface placement
The editor SHALL place armed palette objects at the actual clicked source-architecture surface with visible transient feedback, grid/facing controls and undo/redo. Invalid hits SHALL not create an object. Cancellation and scene/build transitions SHALL remove the mode/ghost without modifying source content.

#### Scenario: Place and undo an object
- **WHEN** a designer arms a kind, clicks a valid surface and undoes/redoes
- **THEN** exactly one correctly owned marker SHALL appear at the documented anchor/orientation and no preview descendant SHALL be serialized

#### Scenario: Navigate or cancel
- **WHEN** Alt navigation, invalid surfaces, Escape, RMB or a scene change occurs
- **THEN** the tool SHALL preserve navigation semantics or cancel as appropriate without accidental placements

### Requirement: Navigable validation
Validation SHALL provide structured issue targets while retaining readable CLI errors. Clicking an issue SHALL select/inspect the relevant current-source node or report that its target is no longer available, without selecting another scene's similarly named node.

#### Scenario: Fix an obstructed spawn
- **WHEN** validation identifies a specific marker and the designer activates its issue row
- **THEN** that marker SHALL be selected in the editor and remain normally editable

### Requirement: Built-level selection
The normal game SHALL list public built authored maps with deterministic names/path IDs, keyboard-accessible scrolling and Back/Escape behaviour. Selection SHALL load through the normal session and persist through restart; the original Start/default and existing mapping shortcut SHALL remain functional. Runtime discovery SHALL not load authoring scenes or instantiate actors while listing maps.

#### Scenario: Play another built map
- **WHEN** a player selects a catalog entry and later restarts
- **THEN** the same map SHALL be recreated with fresh gameplay state and no duplicate actors

### Requirement: Checked export gate
The Cinderkeep checked-export action and CLI wrapper SHALL validate saved public source/build associations and versioned fingerprints before invoking export. Missing/stale/orphaned maps or existing outputs SHALL prevent exporter invocation and SHALL NOT alter prior artifacts. Stock Godot export's bypass limitation SHALL be visible rather than represented as cancellable.

#### Scenario: Source changed since build
- **WHEN** checked export is requested after a source or external source-resource change
- **THEN** the tool SHALL identify the affected map and refuse export until its build is current

### Requirement: Preserved gameplay and versioned evidence
Combat tuning, accepted maps/assets/vendor pin and previous versioned builds SHALL remain unchanged. The new workflow SHALL be verified in actual editor input/UI, source and external packaged-resource tests, with human usability acceptance recorded only when reported.

#### Scenario: Validate the polished workflow
- **WHEN** regression and export checks run
- **THEN** existing gameplay fingerprints SHALL match and runtime packages SHALL not require editor addons/source scenes/credentials
