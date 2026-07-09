# GitHub Issue Map - Bot Traffic Resilience Modernization

This file maps the Conductor track to GitHub Issues and the expected small-PR delivery sequence.

## Delivery Rules

- Use one parent issue for the whole modernization program.
- Use subissues for reviewable units; each subissue should normally close through one focused PR.
- A PR is too large if it combines policy, tooling, runtime behavior, rollout, and documentation in one change.
- No known risk may be accepted as low risk. Fix it, prove it false positive, mitigate it, or create a blocking follow-up before closing the subissue.
- Every PR must name the feedforward guide it changes or follows and the feedback sensor that verifies it.
- Prefer advisory or disabled-by-default pilots before mandatory enforcement or user-visible behavior.

## Parent Issue

| Issue | Title | Purpose | Status |
| --- | --- | --- | --- |
| #1 | Bot resilience modernization delivery program | Coordinates the full issue/subissue/PR sequence for this Conductor track. | Open |

## Subissues

| Issue | Title | Expected PR Scope | Harness Priority | Status |
| --- | --- | --- | --- | --- |
| #2 | Add no-risk and harness delivery policy | Conductor workflow, product guidelines, PR/issue standards only. | Feedforward guide | Open |
| #3 | Create harness map and sensor coverage baseline | Add a harness map for maintainability, architecture fitness, and behaviour. | Feedforward guide plus sensor inventory | Open |
| #4 | Audit runtime, CI, security, deployment, and bot controls | Add current-state audit artifact and validation script if useful. | Computational sensor baseline | Open |
| #5 | Create modernization tool decision record | Adopt/pilot/defer/reject matrix for proposed tools. | Feedforward guide | Open |
| #6 | Add bot-traffic benchmark baseline | Add repeatable benchmark fixtures and baseline capture docs. | Computational feedback sensor | Open |
| #7 | Add Ruby/JIT compatibility and Vernier profiling pilot | One runtime/profiling pilot with rollback notes. | Runtime and performance sensors | Open |
| #8 | Add DevSecOps and dependency scanning gates | Brakeman, Bearer, bundler-audit, dependency review, permissions. | Security feedback sensors | Open |
| #9 | Add feature-flagged bot challenge escalation | Narrow Turnstile-style challenge pilot with tests and rollback. | Behaviour and abuse-resilience sensors | Open |
| #10 | Add contract validation for external inputs | dry-validation contracts for selected API/bot-control boundaries. | Behaviour and correctness sensors | Open |
| #11 | Evaluate Rails Solid components and Kamal | Decision records and isolated pilots, no wholesale migration. | Architecture fitness sensors | Open |
| #12 | Add type, property, mutation, and E2E pilots | Scoped Steep/RBS, PBT, Mutant, Cuprite/Playwright, Syntax Tree, Herb pilots. | Advanced feedback sensors | Open |
| #13 | Add rollout metrics and operator runbooks | Metrics, incident response, disablement, triage, release gates. | Runtime feedback sensors | Open |

## PR Standard

Every PR linked to this track must include:

- Parent issue and subissue links.
- Exact scope and explicit non-goals.
- No-risk evidence: all known findings fixed, verified false positive, mitigated, or blocking follow-up.
- Harness feedforward: the spec, plan, guide, contract, ADR, or runbook steering the change.
- Harness feedback: tests, linters, scanners, type checks, benchmarks, logs, metrics, or review sensors that validate the change.
- Rollback path or feature flag for operational/user-visible changes.
- Verification commands and results.
