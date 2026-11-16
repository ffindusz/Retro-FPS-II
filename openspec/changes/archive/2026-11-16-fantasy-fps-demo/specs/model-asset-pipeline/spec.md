## ADDED Requirements

### Requirement: Reproducible Godot project
The repository SHALL contain a Godot 4.7 project with GDScript gameplay, the Compatibility renderer, configured input actions, and a runnable main scene. The project SHALL NOT require .NET, runtime network access, a Meshy.ai account, or API credentials. Setup documentation SHALL identify the editor version and how to import, run, and test the project.

#### Scenario: Open and run the project offline
- **WHEN** a developer opens the delivered project in the documented editor and imports its bundled assets without network access
- **THEN** the project reaches the start screen and can launch the demo without missing scripts or required resources

### Requirement: Playable placeholders and replaceable visuals
Weapons, enemies, and decorative models SHALL use wrapper scenes that separate imported visuals from gameplay collision and scripts. The complete gameplay loop SHALL work with bundled primitive placeholders. Replacing a visual SHALL NOT require rewriting combat, progression, or collision behavior.

#### Scenario: Run without generated models
- **WHEN** no final Meshy.ai models have been supplied
- **THEN** the bundled placeholders support start, combat, key collection, victory, defeat, and restart, and the build is identified as a placeholder prototype

#### Scenario: Replace a visual
- **WHEN** a compatible imported mesh replaces a wrapper's placeholder visual
- **THEN** its scale, orientation, and pivot can be adjusted independently while existing gameplay and collision continue to work

### Requirement: Documented Meshy.ai import and provenance
The asset workflow SHALL document manual Meshy.ai generation/export or explicitly authorized local API authoring, glTF/GLB import with textures, meter-based scale, orientation, grip/ground pivot alignment, material review, collision separation, and model budgets. API authoring SHALL remain separate from the game, avoid logging credentials, record task IDs, and avoid automatic duplicate paid submissions. An asset manifest SHALL identify each bundled asset's origin, local path, placeholder/final status, import settings, and known license/attribution status. Unknown rights SHALL be marked unresolved rather than asserted.

#### Scenario: Import and review a generated model
- **WHEN** a developer follows the workflow for a supplied Meshy.ai GLB
- **THEN** the model appears in its wrapper with reviewed textures, scale, orientation, and independently authored collision, and its provenance is recorded

#### Scenario: Encounter unresolved redistribution rights
- **WHEN** an asset's redistribution permission is unknown
- **THEN** the manifest marks that uncertainty and the asset is excluded from the distributable build until rights are resolved

### Requirement: Honest art integration status
Completing the Meshy.ai art pass SHALL require imported 3D visuals for both weapons, both enemy archetypes, and at least two decorative props, reviewed in gameplay. Missing final assets SHALL remain explicitly tracked as incomplete; successful placeholder gameplay SHALL NOT be reported as completed Meshy.ai integration.

#### Scenario: Review final demo art
- **WHEN** the Meshy.ai art pass is marked complete
- **THEN** both weapons, both enemy archetypes, and at least two props use reviewed imported models with recorded provenance and resolved distribution rights

### Requirement: Verifiable Windows demo packaging
The project SHALL provide a Windows desktop export preset and instructions for matching Godot export templates. Release acceptance SHALL include a successful offline exported-build playthrough, passing headless checks, and recorded manual results covering controls, 2D HUD, 3D weapons, combat, pause, win/lose flows, and repeated restart. Missing export prerequisites SHALL be reported as blockers rather than successful validation.

#### Scenario: Validate an exported demo
- **WHEN** the required templates are installed and the Windows export is produced
- **THEN** the exported game launches offline and supports a full win/lose/restart loop without missing resources, with validation results recorded

#### Scenario: Export templates are missing
- **WHEN** packaging is attempted without matching export templates
- **THEN** the missing prerequisite is documented and export acceptance remains incomplete
