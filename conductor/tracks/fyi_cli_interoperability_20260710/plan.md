# Implementation Plan: fyi-cli Interoperability

## Phase 1: Contract evidence

- [ ] Issue #24: Audit and publish the exact server/client contract.
- [ ] Record the paired fyi-cli issue and contract version in this plan.
- [ ] Add a drift sensor for every documented header and endpoint behavior.
- [ ] Verify no live network is required by the contract suite.

## Phase 2: Server conformance fixtures

- [ ] Issue #25: Add focused fixtures/specs for back-pressure, 304, and bulk export.
- Paired fyi-cli issue: https://github.com/edithatogo/fyi-cli/issues/142
- Paired fyi-cli draft PR: https://github.com/edithatogo/fyi-cli/pull/150
- [ ] Test absent, malformed, degraded, throttled, conditional, and bounded cases.
- [ ] Run RuboCop, Brakeman, dependency audit, and focused tests with zero untriaged findings.

## Phase 3: Identity and operations

- [ ] Issue #26: Define token, User-Agent, rotation, and staged rollout behavior.
- [ ] Prove no secret appears in logs, traces, fixtures, or errors.
- [ ] Add rollback and disablement runbook steps.

## Phase 4: Cross-repo verification

- [ ] Issue #27: Reconcile the paired fyi-cli implementation evidence.
- [ ] Run the shared offline contract suite and only an explicitly enabled bounded smoke test.
- [ ] Close this track only when every known risk is fixed, verified false positive, or blocked by a dated disabled follow-up.

## Paired endorsed-route proposal

- Fork-local Alaveteli planning issue: https://github.com/edithatogo/alaveteli/issues/28
- Paired fyi-cli planning issue: https://github.com/edithatogo/fyi-cli/issues/148
- Paired Conductor track: `conductor/tracks/endorsed_client_route_20260710/`
- Upstream Alaveteli issue/PR creation remains disabled until the shared
  evidence gate passes.

## PR standard

One child issue maps to one PR. Each PR must state scope, non-scope, test-first
evidence, security/quality sensors, rollback, and harness changes. Parent and
paired issue links are mandatory. No child issue is closed by a documentation
claim alone when production behavior remains unverified.
