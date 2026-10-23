## ADDED Requirements

### Requirement: Fixed authorization and source
The tool SHALL permit at most one 5-credit rig and one 9-credit batch for actions 0, 21 and 219, using only the original hash-pinned textured Warden and a 14-credit ceiling.

#### Scenario: Preflight succeeds
- **WHEN** credentials, sufficient balance and the exact live action entries are verified
- **THEN** explicit submission MAY create only the two authorized stages without buying credits, replacing the model or adding actions

### Requirement: No automatic paid retries
Each paid stage SHALL reserve its cost and checkpoint before POST, persist a returned ID before polling, and refuse resubmission after unknown outcomes or terminal failures. Resuming a saved task SHALL not create another paid task.

#### Scenario: Submission result is ambiguous
- **WHEN** a POST fails locally without a confirmed saved task ID
- **THEN** the record SHALL remain blocked and later runs SHALL not issue a replacement POST

#### Scenario: A stage is resumed
- **WHEN** a saved task ID exists
- **THEN** only status/download requests SHALL be used for that stage

### Requirement: Credential-safe durable outputs
Keys, upload data URIs, raw credential-bearing errors and signed URLs SHALL NOT be logged or stored. Results SHALL be downloaded without forwarding authorization and saved with sanitized IDs/status/charge/hash provenance outside the project before import review.

#### Scenario: Task returns download URLs
- **WHEN** files are downloaded and a record written
- **THEN** the record SHALL contain only approved metadata and hashes, not the URLs or credentials
