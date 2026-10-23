## ADDED Requirements

### Requirement: Six-stage fixed budget
The pilot SHALL permit exactly three 20-credit standard A-pose previews, one 10-credit selected PBR refine, one 5-credit rig and one 15-credit five-action batch, with total reservations at most 90 credits. Extra variants/actions, Ultra/standalone remesh/conversion and paid replacement requests SHALL be refused.

#### Scenario: Submit the planned pilot
- **WHEN** valid credentials, sufficient balance, fixed plan and explicit submission are present
- **THEN** only the six authorized stages SHALL be eligible for a first POST

### Requirement: Durable safe resume
Each paid request SHALL be reserved/checkpointed before POST and its ID saved before polling. Unknown outcomes or failed/canceled tasks SHALL block replacement; resume without explicit submission SHALL perform no new paid requests. Credentials and signed URLs SHALL not be persisted.

#### Scenario: A submission times out
- **WHEN** no task ID has been confirmed locally
- **THEN** the saved ambiguous stage SHALL prevent a replacement POST

### Requirement: Single selected downstream candidate
Downstream stages SHALL reference one explicitly selected successful preview. Selection SHALL be immutable after any downstream reservation. No candidate selection SHALL imply permission to exceed the 90-credit scope.

#### Scenario: Change the winner after texturing starts
- **WHEN** a different candidate is requested after a downstream stage is reserved
- **THEN** the tool SHALL preserve the record and refuse another paid branch
