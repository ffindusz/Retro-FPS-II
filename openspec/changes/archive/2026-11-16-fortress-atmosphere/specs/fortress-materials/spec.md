## ADDED Requirements

### Requirement: Original bundled environment surfaces
The demo SHALL provide distinguishable rough-stone wall, flagstone floor, and worn-trim materials using original tileable assets authored offline. The initial set SHALL contain at most six 512×512 texture images, with mipmaps and repeat sampling, plus solid-color accent materials as needed. Gameplay/export SHALL NOT require runtime asset generation, external downloads, paid services, new Meshy models, or a renderer upgrade.

#### Scenario: Open the bundled level offline
- **WHEN** the project or exported demo loads with authoring tools and network access unavailable
- **THEN** environment material resources resolve locally and walls, floors, and trim show their distinct authored surfaces

### Requirement: Consistent environment mapping and shared resources
Environment mapping SHALL maintain consistent documented world scale across differently sized boxes and adjacent surfaces rather than stretch a texture once per object. Materials/textures SHALL be shared by surface family/area variant rather than duplicated per block. The material pass SHALL NOT change imported actor/weapon/prop materials or the existing model texture limits.

#### Scenario: Compare a long wall and a short pillar
- **WHEN** surfaces of the same family are viewed together
- **THEN** the stone pattern has consistent world scale and orientation without large object-specific stretching or obvious boundary seams

#### Scenario: Verify existing model resources
- **WHEN** atmosphere materials are applied to the world
- **THEN** the six source model files, normalized visuals, and imported texture limits remain unchanged

### Requirement: Reproducible authoring and a presentation fallback
Environment asset provenance SHALL record authoring source, seeds/parameters, sizes, and import settings. A developer-only atmosphere toggle SHALL default on and restore the previous flat world presentation when disabled without changing gameplay. Geometry-only authoring/navigation checks SHALL remain usable without a player or active audio loops.

#### Scenario: Disable atmosphere for comparison
- **WHEN** the developer starts a run with the presentation toggle disabled
- **THEN** the pre-pass world presentation is available while gameplay, controls, encounters, and objectives retain the same behavior
