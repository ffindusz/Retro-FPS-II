## ADDED Requirements

### Requirement: Original bundled night sky
Atmosphere-enabled gameplay SHALL display an original static moonlit panorama with sparse stars and cloud detail above the fortress. One bundled 1024x512 image SHALL load offline without generation, downloads or credentials. Its source parameters and file hash SHALL be recorded, and its horizontal seam SHALL be closed.

#### Scenario: Look above the fortress
- **WHEN** the player looks up in an atmosphere-enabled run
- **THEN** a moonlit cloud/star sky replaces the flat background and its moon aligns with the existing directional light

### Requirement: Background-only presentation
The sky SHALL NOT supply ambient illumination or reflections, change existing ambient/directional/torch/weapon light values, add lights or geometry, or alter gameplay fingerprints. It SHALL remain static during pause and require no per-frame authoring or animation.

#### Scenario: Compare lighting and gameplay
- **WHEN** a new sky-enabled run is created
- **THEN** explicit color ambient and existing light values remain in effect and collision/navigation/placements/combat match the accepted baseline

### Requirement: Disposable sky and flat fallback
Each run SHALL own its sky/environment while sharing the bundled texture resource. Restart/menu disposal SHALL retain no old world nodes. With the developer atmosphere toggle disabled, the prior flat background SHALL remain without a sky.

#### Scenario: Restart or disable atmosphere
- **WHEN** the player restarts and the developer later starts a run with atmosphere disabled
- **THEN** the old world is disposed, the new normal run has its own sky, and the disabled run retains the flat background

### Requirement: Honest sky review
Technical checks SHALL cover resources, seam, lifecycle, light isolation and rendered 720p/1080p views. Prior texture approval SHALL NOT be treated as approval of the new sky or unreported lighting/audio/offline acceptance.

#### Scenario: Await sky feedback
- **WHEN** technical/render checks pass before human sky review
- **THEN** the evidence is recorded while new visual approval and earlier unreported acceptance remain open
