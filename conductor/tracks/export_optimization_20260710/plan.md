# Plan: Optimize Bulk Export API

## Phase 1: Baseline and Harness Setup

- [ ] Task: Register issue-led delivery and benchmark harness
    - [ ] Create or update the fork-local parent issue and small subissue map
    - [ ] Add a benchmark command for bulk export allocations, query count, and latency
    - [ ] Document the baseline command, expected inputs, and CI/local execution limits
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Baseline and Harness Setup' (Protocol in workflow.md)

## Phase 2: Streaming Export Implementation

- [ ] Task: Add contract-preserving streaming export query
    - [ ] Refactor `SustainabilityController#bulk_export` to stream selected columns in deterministic pages
    - [ ] Resolve public body fields with a join instead of per-row association access
    - [ ] Preserve verified bot enforcement, `limit`, `since`, NDJSON shape, and response headers
    - [ ] Add controller or service specs for authorization, validation, filtering, ordering, and row shape
- [ ] Task: Add performance and security sensors
    - [ ] Add a query-count or allocation guard where practical
    - [ ] Add no-SQL-interpolation review evidence for user-controlled values
    - [ ] Update metrics or runbooks if export telemetry changes
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Streaming Export Implementation' (Protocol in workflow.md)

## Phase 3: Verification and Closeout

- [ ] Task: Run regression and security gate
    - [ ] Run scoped RSpec, RuboCop, Brakeman, and benchmark command where available
    - [ ] Document unavailable local gates and CI follow-up without accepting risk
    - [ ] Confirm no known security, quality, correctness, availability, or operator risk remains
- [ ] Task: Archive track and synchronize docs
    - [ ] Update Conductor track status and issue map
    - [ ] Archive only after implementation commits, plan updates, and notes are complete
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Verification and Closeout' (Protocol in workflow.md)
