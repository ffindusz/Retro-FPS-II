## ADDED Requirements

### Requirement: Preserve accepted gameplay geometry and placement
The atmosphere pass SHALL preserve static collider shapes/transforms/layers, the baked navigation resource, enemy/pickup/key/exit/spawn positions and counts, combat stats, interaction ranges, and objective rules from combat-polish 0.2.1. New trim and decorative props SHALL have no gameplay collision and SHALL NOT obstruct movement, attack/retreat sight corridors, resource access, or imply new usable cover in open routes.

#### Scenario: Compare gameplay fingerprints
- **WHEN** atmosphere-enabled and baseline runs are compared using canonical collider and gameplay-placement snapshots
- **THEN** their gameplay fingerprints and navigation resource match while presentation nodes/materials can differ

#### Scenario: Complete the existing route
- **WHEN** the player follows the entrance/courtyard/crypt/key/exit route with depleted mana
- **THEN** movement, resource-free melee, key collection, and exit interaction remain available without new obstacles or kill-all conditions

### Requirement: Bounded reuse of existing decoration
The level SHALL reuse existing urn/torch models and simple original architectural accents rather than obtain new source models. There SHALL be at most twelve urn instances total and exactly six existing torches with their independent lights. Frames, trim, and pillar accents SHALL remain within existing solid footprints or nonblocking wall margins; no new rooms, roofs, ceilings, or visual walls across open gameplay space SHALL be added.

#### Scenario: Restart a dressed run repeatedly
- **WHEN** a fresh run is created multiple times
- **THEN** each run has the same bounded decorative placement and no accumulating props, lights, or additional collision

### Requirement: Preserve and strengthen route landmarks
The courtyard entrance, crypt opening, key area, and sealed exit SHALL have coherent material/trim/prop cues that distinguish their roles without changing positions or mechanics. Existing useful world signs and E interaction feedback SHALL remain available, and dressing SHALL NOT conceal resource pickups or objective indicators.

#### Scenario: Read the route and objective
- **WHEN** the player approaches the existing crypt opening, key area, and locked/unlocked exit
- **THEN** the visual treatment supports recognition while the original objective and interaction messages still work
