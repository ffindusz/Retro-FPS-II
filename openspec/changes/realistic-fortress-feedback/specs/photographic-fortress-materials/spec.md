## ADDED Requirements

### Requirement: Licensed bundled photographic stone
The default atmosphere-enabled demo SHALL use locally bundled CC0 photographic stone color, OpenGL normal and roughness maps, with no more than six new maps capped at 1024px. Provenance SHALL record official source/license URLs, authors, physical scale and verified file hashes. Runtime SHALL NOT download assets or require credentials.

#### Scenario: Start without network access
- **WHEN** the imported project or packaged demo starts a run without network access
- **THEN** photographic walls, floors and trim resolve from bundled resources with active normal/roughness mapping

### Requirement: Shared physically scaled presentation
Stone materials SHALL use shared world-aligned repeating mipmapped resources at approximately two meters per wall tile and 1.8 meters per floor tile. Trim SHALL reuse wall maps. Collision, navigation, actor materials/models, gameplay placement and tuning SHALL remain unchanged.

#### Scenario: Compare different-sized surfaces
- **WHEN** long walls, pillars and floors are rendered
- **THEN** photographic detail has consistent physical scale without object-specific stretching and gameplay fingerprints match the original baseline

### Requirement: Separate historical and new acceptance
Original procedural assets and their provenance SHALL remain intact. New technical/render evidence SHALL NOT be reported as human approval of photographic materials.

#### Scenario: Await updated walkthrough
- **WHEN** new technical checks pass without new user feedback
- **THEN** new visual acceptance remains pending and prior walkthrough feedback remains attributed to 0.3
