## 1. Baseline and photographic materials

- [x] 1.1 Capture current 0.3 fixed views and same-machine performance; verify official CC0 licensing and download/checksum six 1K wall/floor maps.
- [x] 1.2 Record authors, source/license/download URLs, scales, checksums and import settings; apply shared photographic albedo/roughness/normal maps with unchanged gameplay.
- [x] 1.3 Adapt material assertions and add offline provenance/hash/map-budget checks while retaining original accepted-source checks.

## 2. Bounded dynamic lighting

- [x] 2.1 Enable exactly two existing torch shadow sources with self-shadow-safe emitters, preserving six lights, transforms, ranges and modulation.
- [x] 2.2 Add a shared six-light budget for short cast/impact flashes and projectile-following lights with pause, resolution, terminal, fallback and restart cleanup.
- [x] 2.3 Add focused bounds, actual projectile ownership, flash timing, pause and teardown regression coverage.

## 3. Unique key pickup sound

- [x] 3.1 Author only the new original key cue and preserve the eleven accepted WAV hashes/import settings.
- [x] 3.2 Publish confirmed successful key pickup events and route a distinct local cue through existing deduplication, volume/mute and voice limits.
- [x] 3.3 Cover successful/duplicate/already-owned/enemy/paused/dead/muted key collection, local playback and cleanup without false hit presentation.

## 4. Validation and delivery

- [x] 4.1 Run source regression and offline asset/tool checks, and prove the new behavior tests fail when the corresponding implementation is disabled.
- [x] 4.2 Render matching 720p/1080p views and active lighting, compare the same-machine baseline and reduce cost if needed.
- [x] 4.3 Verify normal startup; rebuild/check the Windows package if matching export templates exist, otherwise record the delivery blocker.
- [x] 4.4 Update version, controls, asset/audio provenance, evidence, known limitations and prior-feedback attribution without completing old acceptance tasks.

## 5. Human acceptance

- [ ] 5.1 Obtain a human review of photographic stone matching, normal relief, torch-shadow readability/comfort and spell-light brightness/performance.
- [ ] 5.2 Obtain a human listening check of the unique key cue plus a complete run/offline result/restart review; do not infer unreported outcomes.

The user subsequently approved the photographic textures ("textures are good"). Task 5.1 stays open for its remaining detailed lighting/performance criteria; the new sky has its own review task.
