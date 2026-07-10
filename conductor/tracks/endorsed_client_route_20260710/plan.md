# Implementation Plan: Endorsed Client Route

## Phase 0: Paired proposal

- [x] Create fork issue #28 and cross-reference fyi-cli #148.
- [x] Record the shared no-known-risk and upstream-disabled evidence gate.
- [ ] Reconcile this proposal with the existing contract issues #23-#27.
- [ ] Produce a server-side threat model and abuse-case matrix.

## Phase 1: Server contract and controls

- [ ] Define versioned capability discovery and negotiation.
- [ ] Define disabled-default configuration, allowlists, quotas, maintenance
  windows, revocation, and emergency disablement.
- [ ] Define authentication, identity, token rotation, audit, metrics, and
  secret-redaction requirements.
- [ ] Define bounded export authorization and privacy constraints.
- [ ] Add offline fixtures/specs for enabled, disabled, unauthorized,
  throttled, degraded, revoked, and over-budget behavior.

## Phase 2: Fork implementation slices

- [ ] Create one focused issue/PR per server control concern.
- [ ] Add harness tests and security/quality gates with no default live network.
- [ ] Document operator rollout, status, rollback, and kill-switch procedures.
- [ ] Reconcile evidence with the paired fyi-cli track after each slice.

## Phase 3: Upstream handoff

- [ ] Prepare a maintainer-readable problem/solution and limitations package.
- [ ] Obtain shared evidence-gate sign-off in both repositories.
- [ ] Open one upstream Alaveteli discussion issue only after maintainer package
  completion.
- [ ] Submit small upstream PRs only after maintainer direction.

## Closure gate

Do not close while any known security, privacy, availability, correctness, or
quality risk lacks a fix, deterministic sensor, or explicit disabled follow-up.

