## ADDED Requirements

### Requirement: Collision-aware first-person movement
The player SHALL move with WASD relative to camera yaw, use gravity and solid-world collision, and jump with Space only while grounded. Diagonal input SHALL NOT increase planar speed above the configured movement speed.

#### Scenario: Move and collide
- **WHEN** the player moves forward or diagonally into a solid wall during gameplay
- **THEN** the player remains outside the wall and planar speed does not exceed the configured movement speed

#### Scenario: Grounded jump
- **WHEN** the player presses jump while grounded and presses it again while airborne
- **THEN** the first press starts a jump and the airborne press does not create an additional jump

### Requirement: Mouse-look and capture
The player SHALL use mouse movement for yaw and pitch, clamp pitch to prevent camera inversion, and capture the cursor only during active gameplay. Menus, pause, defeat, victory, and loss of application focus SHALL release the cursor; focus loss during gameplay SHALL pause the run rather than leave combat active.

#### Scenario: Look around
- **WHEN** the player moves the mouse during active gameplay
- **THEN** the camera responds with yaw and bounded pitch without rolling or flipping over

#### Scenario: Lose application focus
- **WHEN** the application loses focus during gameplay
- **THEN** the run pauses and the cursor is released until the player explicitly resumes

### Requirement: Player health and terminal death
Player health SHALL remain between zero and its configured maximum. Damage SHALL update health and emit a single death transition on reaching zero; a dead player SHALL NOT move, attack, collect items, or interact with the exit.

#### Scenario: Receive lethal damage
- **WHEN** incoming damage equals or exceeds the player's remaining health
- **THEN** health becomes zero, the run enters defeat once, and further gameplay input is ignored

#### Scenario: Bound healing
- **WHEN** a living player receives more healing than the missing health
- **THEN** health becomes the configured maximum without exceeding it
