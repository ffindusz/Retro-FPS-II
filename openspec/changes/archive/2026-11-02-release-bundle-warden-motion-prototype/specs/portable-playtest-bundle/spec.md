## ADDED Requirements

### Requirement: Preserve the accepted Windows baseline

The packager SHALL verify the size and SHA-256 of the accepted 0.4.1 EXE/PCK against a tracked artifact record and SHALL NOT re-export or modify them.

#### Scenario: Accepted artifacts are packaged
- **WHEN** the recorded binaries are available and match the record
- **THEN** their exact bytes SHALL be included in a versioned Windows x64 ZIP

#### Scenario: A binary differs from the accepted build
- **WHEN** either recorded size or hash differs
- **THEN** packaging SHALL fail without replacing an existing bundle

### Requirement: Only player files and attribution enter the bundle

The ZIP SHALL contain an explicit allowlist of EXE, PCK, controls/objective README, asset credits, verbatim Godot engine/component notices and per-file SHA-256 checksums. It SHALL NOT infer an overall project license or include developer tools, credentials or prototype files.

#### Scenario: Unrelated files exist beside the binaries
- **WHEN** an unrelated or private file exists in the build directory
- **THEN** it SHALL not enter the ZIP

#### Scenario: Bundle is extracted for playtesting
- **WHEN** the player extracts the ZIP
- **THEN** EXE and PCK SHALL be adjacent and the README SHALL describe launch, controls, objective and current unrigged limitations without requiring an editor

### Requirement: Packaging is repeatable and nondestructive

Identical inputs SHALL produce identical ZIP bytes. A different existing output SHALL be left untouched and reported as an error.

#### Scenario: Repeated packaging
- **WHEN** all allowed inputs are unchanged
- **THEN** repeated packaging SHALL produce identical archive hashes and passing CRC/checksum validation
