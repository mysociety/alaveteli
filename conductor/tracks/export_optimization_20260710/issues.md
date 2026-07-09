# GitHub Issue Map - Bulk Export Optimization

This file maps the Conductor track to fork-local GitHub issues and the
expected small-PR delivery sequence.

## Parent Issue

- `#14` Optimize bulk export API for large datasets
  - Purpose: coordinate benchmark, implementation, verification, and closeout.
  - Status: Open

## Subissues

- `#15` Add bulk export benchmark harness
  - Scope: benchmark command and baseline documentation only.
  - Harness priority: computational feedback sensor.
  - Status: Open
- `#16` Implement contract-preserving streaming bulk export
  - Scope: streaming query implementation and output compatibility specs.
  - Harness priority: behaviour and performance sensors.
  - Status: Open
- `#17` Verify and close bulk export optimization
  - Scope: regression and security gates, issue-map closure, and archive.
  - Harness priority: release-gate sensors.
  - Status: Open

## PR Standard

Every PR linked to this track must include:

- Parent issue and subissue links.
- Exact scope and explicit non-goals.
- No-risk evidence for SQL safety, output compatibility, availability, and
  operator rollback.
- Harness feedforward: spec, plan, contract, benchmark, or runbook guidance.
- Harness feedback: specs, query-count or allocation evidence, scanners, and
  benchmark results.
- Verification commands and results.
