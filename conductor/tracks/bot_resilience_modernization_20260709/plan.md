# Implementation Plan - Bot Traffic Resilience Modernization

## Phase 1: Baseline and Tool Decision Matrix [checkpoint: 89e4331]

- [x] Task: GitHub Issue Decomposition and PR Standards [bfd1962]
    - [x] Create a parent GitHub issue for the bot resilience modernization program linked to this Conductor track
    - [x] Create PR-sized subissues for risk policy, harness map, audit, decision record, benchmark baseline, runtime profiling, DevSecOps, challenge escalation, contracts, infrastructure pilots, advanced testing, and rollout documentation
    - [x] Update the PR template so every PR records linked issue, scope boundary, no-risk evidence, harness feedforward guide, harness feedback sensor, tests/scanners, and rollback path
    - [x] Add issue templates for parent modernization issues and small implementation subissues
    - [x] Maintain a track issue map that records GitHub issue numbers, expected PR size, and current status
- [x] Task: Repository Risk and Harness Policy [0ef2bd6]
    - [x] Add no-accepted-known-risk language to Conductor workflow, product guidelines, Definition of Done, deployment checklist, and review checklist
    - [x] Add harness-engineering guidance that distinguishes feedforward guides, computational feedback sensors, inferential feedback sensors, and sensor timing
    - [x] Verify the policy blocks low-severity security and quality findings unless they are fixed, mitigated, feature-flagged off, or tracked as blocking follow-up
- [x] Task: Runtime, CI, Security, and Deployment Audit [0ef2bd6]
    - [x] Write an audit spec or validation script that captures current Ruby, Rails, Bundler, CI, deployment, security, and bot-control tooling state
    - [x] Document current repository evidence, including Rails 8.0.x, Ruby 3.4.x, Rack::Attack, Sidekiq, Redis, Memcached, existing GitHub Actions, and Brakeman configuration
    - [x] Verify current upstream Ruby and Rails release targets during implementation and record production versus experimental lanes
- [x] Task: Tool Recommendation Decision Record [0ef2bd6]
    - [x] Create a decision record classifying each proposed tool as adopt, pilot, defer, or reject
    - [x] Include explicit reasoning for Ruby latest, Vernier, ZJIT/YJIT, GitHub Actions DevSecOps, Kamal, optimized Bundler caching, parallel tests, Bearer, Brakeman, Dawnscanner, dependency auditing, Rails Solid components, Syntax Tree, Herb, RBS/Steep, Sorbet, rbs-inline, dry-validation, PBT, Mutant, Cuprite/Playwright, Rack::Attack, and Turnstile
    - [x] Update `conductor/tech-stack.md` only for tools accepted for implementation
- [x] Task: Harness Map and Sensor Coverage Baseline [0ef2bd6]
    - [x] Create a harness map covering maintainability, architecture fitness, and behaviour controls across the repository
    - [x] Classify each guide or sensor as feedforward, computational feedback, inferential feedback, or runtime feedback
    - [x] Record when each sensor runs: local task loop, pre-commit, pull request, scheduled drift scan, release gate, or runtime monitoring
    - [x] Identify gaps where repeated mistakes or high-impact risks lack both a guide and a sensor
- [x] Task: Bot-Traffic Benchmark Baseline [0ef2bd6]
    - [x] Add repeatable benchmark fixtures for public request pages, public body directory/search, `/api/v1/rate_limit`, `/api/v1/bulk_export`, Rack::Attack, and Sidekiq bulk queue paths
    - [x] Capture baseline latency, allocation, memory, queue-depth, cache-hit, and rate-limit overhead metrics
    - [x] Store baseline output in a documented, reproducible location
- [x] Task: Conductor - User Manual Verification 'Phase 1: Baseline and Tool Decision Matrix' (Protocol in workflow.md) [89e4331]

## Phase 2: Runtime and Profiling Modernization [checkpoint: f888ff1]

- [x] Task: Ruby Version and JIT Compatibility [88fc964]
    - [x] Write tests or CI checks proving the selected Ruby version source is honored by local scripts and GitHub Actions
    - [x] Add an explicit Ruby version source or repository-approved equivalent and align generated deployment defaults with the supported Ruby 3.4 patch lane
    - [x] Add a non-blocking Ruby 4.0 compatibility CI lane
    - [x] Benchmark YJIT and ZJIT modes against the bot-traffic baseline and document production readiness
- [x] Task: Vernier Profiling Harness [b425ae4]
    - [x] Add Vernier as a development/test profiling dependency if compatibility checks pass
    - [x] Add profiling scripts for representative request, search, bulk export, rate-limit, and queue workloads
    - [x] Document how operators capture, store, and compare profiles during bot traffic incidents
- [x] Task: Runtime Rollback and Operations Notes [b425ae4]
    - [x] Document environment variables and deployment settings for enabling or disabling JIT modes
    - [x] Add rollback notes for reverting Ruby or profiling changes without touching application data
- [x] Task: Conductor - User Manual Verification 'Phase 2: Runtime and Profiling Modernization' (Protocol in workflow.md) [f888ff1]

## Phase 3: CI Throughput and DevSecOps [checkpoint: 56fcde4]

- [x] Task: Faster CI Execution [ac4734e]
    - [x] Add workflow assertions or CI dry-run checks for expected job structure and Ruby version alignment
    - [x] Keep `ruby/setup-ruby` Bundler caching and add explicit Bundler job/retry settings where useful
    - [x] Split core specs, nested gem specs, lint, and security checks into separately visible jobs
    - [x] Add `parallel_tests` or matrix sharding for RSpec with deterministic database setup and coverage merge behavior
- [x] Task: Security Scanning and Dependency Gates [ac4734e]
    - [x] Add Brakeman as a resolvable CI dependency and make Brakeman warnings visible in GitHub Actions
    - [x] Add Bearer scanning with SARIF upload and least-privilege `security-events: write` permissions where supported
    - [x] Add bundler-audit and GitHub dependency-review-action for Ruby dependency vulnerability checks
    - [x] Evaluate Dawnscanner in advisory mode and document whether it is compatible enough to keep
    - [x] Review action versioning and workflow permissions for supply-chain hardening
    - [x] Fail or block on all untriaged findings, including low-severity scanner findings, until fixed, mitigated, or converted into blocking Conductor follow-up
- [x] Task: CI Developer Documentation [ac4734e]
    - [x] Document local commands matching each CI job
    - [x] Document expected triage flow for Brakeman, Bearer, bundler-audit, dependency-review, and parallel test failures
- [x] Task: Conductor - User Manual Verification 'Phase 3: CI Throughput and DevSecOps' (Protocol in workflow.md) [56fcde4]

## Phase 4: Bot Challenge and Contract Boundaries [checkpoint: 8a2ed40]

- [x] Task: Feature-Flagged Turnstile Challenge [de2ea46]
    - [x] Write request and system specs for challenge escalation on suspicious interactive traffic
    - [x] Verify normal browsing, request creation, verified bot access, and accessibility-compatible fallback behavior
    - [x] Integrate server-side challenge token validation through a Rails-compatible Turnstile adapter or minimal internal adapter
    - [x] Add feature flags, provider outage handling, bypass rules, and translated user-facing strings
- [x] Task: Contract Validation for External Inputs [de2ea46]
    - [x] Add dry-validation contracts for rate-limit API params, bulk export params, bot-token metadata, and challenge validation payloads
    - [x] Keep ActiveRecord and database validations responsible for persistence invariants
    - [x] Add tests proving invalid inputs fail with stable, non-leaky error responses
- [x] Task: Challenge and Contract Rollback [de2ea46]
    - [x] Document how to disable challenges and contract enforcement if false positives affect legitimate FOI users
    - [x] Add metrics for challenge issued, challenge passed, challenge failed, and challenge bypassed events
    - [x] Confirm challenge false-positive risks are not accepted as low risk and have tested disablement, bypass, and rollback controls
- [x] Task: Conductor - User Manual Verification 'Phase 4: Bot Challenge and Contract Boundaries' (Protocol in workflow.md) [8a2ed40]

## Phase 5: Rails 8 Infrastructure Simplification and Deployment [checkpoint: 1b7dfe9]

- [x] Task: Solid Trifecta Evaluation [f2bf75d]
    - [x] Create a decision record comparing Sidekiq, Redis, and Memcached with Solid Queue, Solid Cache, and Solid Cable
    - [x] Prototype Solid Queue or Solid Cache in isolated configuration if dependency compatibility permits
    - [x] Run load, queue-latency, cache-hit, and operational rollback tests before recommending adoption
    - [x] Update `conductor/tech-stack.md` only if a Solid component is accepted
- [x] Task: Kamal Deployment Pilot [f2bf75d]
    - [x] Add a Kamal-compatible example deployment configuration for an Alaveteli install
    - [x] Document registry, secrets, volumes, background jobs, migrations, and rollback behavior
    - [x] Verify the Kamal pilot against a staging-like environment without invalidating existing systemd or legacy deployment examples
- [x] Task: Infrastructure Runbook Updates [f2bf75d]
    - [x] Document when operators should choose legacy deployment, Kamal, Sidekiq, Solid Queue, Redis, Memcached, or Solid Cache
    - [x] Add rollback and incident notes for queue, cache, and deploy failures
- [x] Task: Conductor - User Manual Verification 'Phase 5: Rails 8 Infrastructure Simplification and Deployment' (Protocol in workflow.md) [1b7dfe9]

## Phase 6: Typed, Property-Based, Mutation, and E2E Assurance [checkpoint: f423e3f]

- [x] Task: Gradual Type Checking Pilot [2f9d213]
    - [x] Add Steep, RBS, and rbs-inline configuration for selected new service objects, contracts, and serializers
    - [x] Generate or write initial signatures for bot-control and bulk-export boundaries
    - [x] Evaluate Sorbet as an alternative and document why it is adopted, deferred, or rejected
- [x] Task: Property-Based and Mutation Testing [2f9d213]
    - [x] Add property-based tests for rate-limit windows, retry/back-off parsing, ETag handling, bulk export ordering, and challenge state transitions
    - [x] Add Mutant coverage for pure critical components where runtime stays acceptable
    - [x] Document mutation score, surviving mutants, and follow-up work
- [x] Task: E2E Browser Coverage [2f9d213]
    - [x] Add Cuprite as the default Capybara-compatible E2E driver unless Playwright Ruby client is justified by cross-browser requirements
    - [x] Add E2E tests for challenge flow, public archive access, verified bot bypass, and bulk export discoverability
    - [x] Ensure E2E tests run headlessly in CI without making the normal suite fragile
- [x] Task: Syntax and Template Tooling Pilot [2f9d213]
    - [x] Add Syntax Tree and Herb in check-only mode for selected Ruby and ERB paths
    - [x] Document formatting or template issues without mass-changing unrelated files
- [x] Task: Conductor - User Manual Verification 'Phase 6: Typed, Property-Based, Mutation, and E2E Assurance' (Protocol in workflow.md) [f423e3f]

## Phase 7: Rollout, Monitoring, and Closeout [checkpoint: dea4011]

- [x] Task: Metrics and Operator Runbooks [78eb514]
    - [x] Extend health or metrics output for rate-limit decisions, challenge outcomes, cache hits, bulk export usage, queue latency, and profiling baseline comparisons
    - [x] Add a bot traffic incident runbook covering throttle tuning, challenge enablement, profiling capture, security scan triage, and rollback
    - [x] Document privacy and accessibility considerations for bot challenge telemetry
- [x] Task: Full Regression and Security Gate [78eb514]
    - [x] Run full RSpec, nested gem specs, RuboCop, Brakeman, Bearer, bundler-audit, dependency-review, type checks, PBT, mutation targets, E2E tests, and benchmark comparison as applicable
    - [x] Document skipped or advisory gates with explicit reasons and blocking follow-up for any remaining known risk
    - [x] Define go/no-go thresholds for enabling runtime, challenge, deployment, or infrastructure changes in production
- [x] Task: Final Documentation and Tech Stack Synchronization [78eb514]
    - [x] Update `conductor/tech-stack.md`, `conductor/workflow.md`, and operator-facing docs for accepted tools only
    - [x] Record deferred tools and revisit triggers in the final track notes
    - [x] Confirm the final track state has no accepted low-risk security or quality findings and an updated harness map
    - [x] Confirm all child issues are closed by small, independently reviewable PRs or explicitly carried forward as blocking follow-up
- [x] Task: Conductor - User Manual Verification 'Phase 7: Rollout, Monitoring, and Closeout' (Protocol in workflow.md) [dea4011]
