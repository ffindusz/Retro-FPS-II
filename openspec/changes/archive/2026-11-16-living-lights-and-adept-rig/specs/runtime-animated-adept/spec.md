## ADDED Requirements

### Requirement: Rigged and animated Adept with a real death animation
Model-based Adepts SHALL use a rigged version of the existing Adept model, with skeletal Idle, Walk, cast/attack, Hit and Death clips. On death, the Adept SHALL play the skeletal death clip (the body crumples or falls with limb motion, not a rigid tip-over) and then hold its final pose. Living Adepts SHALL idle, walk while moving and play the cast clip during the ranged windup.

#### Scenario: Kill an Adept
- **WHEN** the player reduces an Adept's health to zero
- **THEN** a skeletal death animation plays to a held pose on the floor, and collision is removed as before

#### Scenario: Adept casts
- **WHEN** an Adept begins a ranged windup
- **THEN** the cast clip plays, and the bolt still spawns at the existing gameplay time and origin

### Requirement: Gameplay remains authoritative
Animation SHALL be presentation-only. Ranged timing, damage, projectile origin, health, collision, navigation, the `died` signal and enemy counts SHALL be unchanged, and the gameplay fingerprints SHALL match the pre-change baseline. Animation SHALL advance on the gameplay clock, freeze while paused, and be freed on restart or menu.

#### Scenario: Fingerprints
- **WHEN** the gameplay suite runs on 0.6.1
- **THEN** every gameplay fingerprint equals its 0.5.1 value

### Requirement: Bounded, recorded Meshy spend
Rigging and animation SHALL use the Meshy API from the existing local key, with:
- a hard ceiling of 40 credits
- no paid retries
- only the existing Adept GLB (checksum-verified) uploaded
- read-only preflight of the balance and the animation library before any paid call

Provenance SHALL record task IDs, chosen action IDs/keys, reported costs, and download sizes and hashes, without credentials or signed URLs. If a paid stage fails or the result is unusable, the Adept SHALL keep the 0.5.1 tween death, and no further spend SHALL happen without new authorization.

#### Scenario: Paid stage fails
- **WHEN** the rig or animation task fails or the output is unusable
- **THEN** no retry is submitted, the failure is recorded, and the shipped build uses the 0.5.1 Adept death fallback

### Requirement: Fallbacks retained
The placeholder Adept and the 0.5.1 rigid-tween death SHALL remain available whenever the animated resources are missing or `use_placeholder` is set. The Warden presentation SHALL be unchanged.

#### Scenario: Animated resource missing
- **WHEN** the animated Adept scene cannot load
- **THEN** the Adept uses the static model with the 0.5.1 tween death, and the run continues without errors
