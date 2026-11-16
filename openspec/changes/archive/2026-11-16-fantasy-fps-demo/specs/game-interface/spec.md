## ADDED Requirements

### Requirement: Readable 2D gameplay HUD
The game SHALL display a 2D HUD above the 3D world and weapon presentation containing a centered crosshair, current/max health, current/max mana, selected weapon, key status, and contextual objective/interaction feedback. Displayed values SHALL follow gameplay state changes without restarting the UI. The HUD SHALL remain readable and unclipped at 1280×720 and 1920×1080.

#### Scenario: Reflect combat and objective changes
- **WHEN** the player takes damage, fires magic, switches weapons, or collects the key
- **THEN** the corresponding HUD indicators update to match current game state

#### Scenario: Resize the window
- **WHEN** the window changes between the supported test resolutions
- **THEN** the crosshair remains centered and HUD indicators remain visible and unclipped

### Requirement: Start screen and controls
The game SHALL launch into a start screen offering Start and Quit and showing the movement, look, jump, attack, weapon-selection, interaction, and pause controls. Menu actions SHALL be operable with both mouse and keyboard.

#### Scenario: Start from the menu
- **WHEN** the player activates Start using the mouse or keyboard
- **THEN** a fresh run begins, the HUD appears, and the cursor is captured for gameplay

### Requirement: Complete pause and resume behavior
Escape during active gameplay SHALL open a pause menu with Resume, Restart, and Quit to Menu. Paused gameplay SHALL freeze player/enemy movement, attacks, cooldowns, projectiles, and pickups while keeping the menu interactive. Resuming SHALL NOT interpret the menu activation click as an attack.

#### Scenario: Freeze an ongoing encounter
- **WHEN** the player pauses while an enemy winds up and a projectile is in flight
- **THEN** gameplay state and timers remain unchanged until resume and menu controls remain usable

#### Scenario: Resume safely
- **WHEN** the player activates Resume
- **THEN** the game continues from the paused state, recaptures the cursor, and does not fire from the activation input

### Requirement: Defeat and victory flows
Defeat and victory SHALL display distinct 2D result screens with Restart and Quit to Menu. Both screens SHALL release the cursor and prevent further gameplay changes. Returning to the menu SHALL dispose of the old run and allow another fresh run.

#### Scenario: Handle defeat
- **WHEN** player health reaches zero
- **THEN** the defeat screen appears once and the player can restart or return to the start screen

#### Scenario: Handle victory
- **WHEN** the player completes the exit objective
- **THEN** the victory screen appears once and the player can restart or return to the start screen

#### Scenario: Return and start again
- **WHEN** the player quits a run to the start screen and then activates Start
- **THEN** the previous run is gone and a fresh playable run begins
