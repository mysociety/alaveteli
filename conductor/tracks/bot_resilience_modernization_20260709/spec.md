# Track Specification - Bot Traffic Resilience Modernization

## 1. Overview
This track extends the immediate Sustainability Suite controls with a deliberate runtime, assurance, deployment, and developer-tooling modernization program for Alaveteli. The goal is to keep the public FOI archive available under increased bot and scraper pressure while improving throughput, operational confidence, security visibility, and regression resistance within the existing Ruby on Rails framework.

The current Sustainability Suite already covers Rack::Attack throttling, rate-limit headers, HTTP caching headers, bulk export, Sidekiq queue offloading, and client-side `fyi-cli` coordination. This track focuses on the next layer: measured runtime upgrades, advanced profiling, DevSecOps CI, deployment simplification, bot challenge escalation, stronger contracts, type-aware boundaries, and higher-value testing.

This track also makes harness engineering a repo-level operating model. Following the approach described by Birgitta Bockeler on martinfowler.com, Alaveteli should combine feedforward guides that steer work before it happens with feedback sensors that let humans and coding agents self-correct after each change. The repo must prefer fast deterministic sensors for every-change checks and reserve inferential review for semantic judgment. No known risk, including low-severity quality or security findings, is acceptable without verified mitigation or a blocking Conductor follow-up.

## 2. Recommendation Summary

### 2.1 Adopt First
*   Add a no-accepted-known-risk policy to Conductor workflow, product guidelines, CI gates, and track completion criteria.
*   Establish harness engineering as the default repo setup: explicit feedforward guides plus computational and inferential feedback sensors across maintainability, architecture fitness, and behaviour.
*   Add a measured Ruby runtime upgrade ladder: keep a supported Ruby 3.4 production lane, update to the latest safe 3.4 patch level, and add a non-blocking Ruby 4.0 compatibility lane.
*   Add Vernier profiling for representative public archive, search, bulk export, and throttling workloads.
*   Add GitHub Actions DevSecOps jobs for Brakeman, Bearer SARIF upload, bundler-audit, and dependency review.
*   Speed up CI with improved Bundler settings, job splitting, and parallel RSpec execution.
*   Add feature-flagged Turnstile-style challenge escalation for suspicious interactive traffic, while preserving verified bot and accessibility paths.
*   Add dry-validation contracts for external API and bot-control boundaries.
*   Add property-based tests for rate-limit windows, cache validators, header parsing, and state transitions.
*   Add scoped mutation testing for pure critical code paths where it provides meaningful signal.

### 2.2 Pilot Before Enforcing
*   Evaluate Ruby JIT modes. YJIT can be benchmarked for production suitability; ZJIT should remain experimental until correctness, crash, and throughput evidence is strong enough.
*   Evaluate Rails 8 Solid Queue, Solid Cache, and Solid Cable against the existing Sidekiq, Redis, and Memcached stack before any migration.
*   Pilot RBS with Steep and rbs-inline on new traffic-control and API contract code before adopting broad type checking. Sorbet should remain an explicit alternative if Steep does not fit the codebase.
*   Pilot Cuprite for Capybara-backed E2E coverage before considering Playwright Ruby client adoption.
*   Pilot Syntax Tree and Herb in check-only mode before any formatter or template-analysis enforcement.
*   Evaluate Dawnscanner as advisory-only because Brakeman and Bearer are better primary security gates for this repository.

### 2.3 Defer Unless Evidence Changes
*   Do not replace Sidekiq, Redis, Memcached, or systemd-style deployment examples simply because Rails 8 offers newer defaults. Treat Kamal and the Rails 8 Solid components as evidence-driven simplification candidates.
*   Do not mass-format the repository until a small check-only pilot proves the formatting/tooling impact is acceptable.
*   Do not roll out user-visible bot challenges broadly. Challenges must be narrow, feature-flagged, accessible, server-side validated, and triggered only by risk signals.

## 3. Functional Requirements

### 3.1 Runtime and Profiling Modernization
*   Establish explicit Ruby version policy for production, CI, and experimental lanes.
*   Align local, CI, and generated deployment configuration with the selected supported Ruby patch level.
*   Add a non-blocking Ruby 4.0 compatibility workflow or matrix lane to expose dependency and framework issues early.
*   Benchmark YJIT and ZJIT using representative workloads before enabling either in production.
*   Add Vernier profiling workflows for high-strain paths:
    *   public request show pages,
    *   public body directory and search,
    *   `/api/v1/rate_limit`,
    *   `/api/v1/bulk_export`,
    *   Rack::Attack request paths,
    *   Sidekiq bulk queue processing.

### 3.1.1 Harness Engineering Operating Model
*   Maintain feedforward guides for agent and human work: `conductor/product.md`, `conductor/product-guidelines.md`, `conductor/tech-stack.md`, `conductor/workflow.md`, code style guides, track specs, track plans, decision records, and runbooks.
*   Maintain computational feedback sensors: RSpec, RuboCop, Brakeman, Bearer, bundler-audit, dependency review, type checks, property-based tests, mutation tests, E2E tests, benchmarks, and architecture checks.
*   Maintain inferential feedback sensors for semantic review, architecture review, and risk review where deterministic tooling cannot fully evaluate intent.
*   Define execution timing for each sensor: local/task-level, pull-request CI, post-merge scheduled drift detection, release gate, or runtime monitoring.
*   When a repeated issue is found, update both the relevant guide and at least one sensor so future work is steered and checked.

### 3.2 CI Throughput and DevSecOps
*   Improve GitHub Actions runtime by using optimized Bundler settings, existing `ruby/setup-ruby` caching, and parallel test execution.
*   Split RSpec, nested gem specs, lint, and security analysis into independently visible jobs.
*   Align RuboCop CI with the repository Ruby version instead of using an older Ruby lane.
*   Add Brakeman to CI as a first-class security gate.
*   Add Bearer scanning with SARIF upload where permissions allow.
*   Add bundler-audit and GitHub dependency review to catch vulnerable dependencies.
*   Review workflow permissions and action version policy for least privilege and supply-chain risk.

### 3.3 Bot Challenge Escalation
*   Add a feature-flagged challenge step for suspicious interactive traffic after softer controls are exhausted.
*   Preserve normal public browsing, request creation, verified bot access, and assistive technology compatibility.
*   Validate challenge tokens server-side and fail closed for forged tokens while failing gracefully for provider outages.
*   Apply challenges only to routes where they reduce abuse without undermining FOI access.

### 3.4 Contracts, Types, and Boundary Safety
*   Add dry-validation contracts for external-facing bot-control and bulk export inputs.
*   Keep persistence rules in ActiveRecord validations and database constraints.
*   Pilot RBS with Steep and rbs-inline on new service objects, contracts, and API serializers.
*   Document whether Sorbet is rejected or deferred after comparing setup cost, Rails compatibility, and ongoing maintenance.

### 3.5 Advanced Verification
*   Add property-based tests for rate-limit counters, retry/back-off parsing, ETag handling, and bulk export invariants.
*   Add mutation testing only for high-value pure code where the runtime is acceptable.
*   Add E2E tests for bot challenge flows, public archive access, and verified bot bypasses using Cuprite or a justified Playwright Ruby client alternative.
*   Add Syntax Tree and Herb pilots in check-only mode for Ruby and ERB analysis.

### 3.6 Deployment and Infrastructure Simplification
*   Add a Kamal deployment pilot or example configuration suitable for Alaveteli operators.
*   Compare Kamal with the existing deployment examples and document rollback and secret-handling behavior.
*   Evaluate Rails 8 Solid Queue, Solid Cache, and Solid Cable against current Redis, Memcached, and Sidekiq operational needs.
*   Update `tech-stack.md` only when a tool is accepted for implementation, as required by the project workflow.

### 3.7 Observability and Runbooks
*   Extend metrics for rate-limit decisions, challenge issuance, challenge pass/fail outcomes, cache hit rates, bulk export usage, queue latency, and profiling baselines.
*   Add operator runbooks for bot traffic incidents, profiling capture, challenge disablement, and CI security triage.

## 4. Non-Functional Requirements
*   **Measured Change:** Runtime and infrastructure changes must be backed by benchmark, profile, compatibility, and rollback evidence.
*   **No Accepted Known Risk:** Known risks, including findings classified as low severity, must be eliminated, mitigated with verified controls, converted into blocking work, or kept behind disabled-by-default feature flags with dated follow-up.
*   **Harnessability:** The repository must become more legible, navigable, and governable for humans and coding agents through explicit guides, scripts, checks, metrics, and runbooks.
*   **Availability:** Bot defenses must protect service availability without making legitimate FOI access fragile.
*   **Accessibility:** Challenge flows must remain compatible with accessibility requirements and translated user-facing strings.
*   **Security:** DevSecOps jobs must use least-privilege GitHub token permissions and publish SARIF only where safe.
*   **Maintainability:** New tooling must have clear ownership, commands, and failure modes documented before becoming mandatory.
*   **Performance:** New middleware, validation, and challenge checks must not exceed the Sustainability Suite latency budget without explicit justification.

## 5. Acceptance Criteria
*   Conductor workflow and product guidelines encode no-accepted-known-risk and harness-engineering principles for the whole repository.
*   A harness map identifies feedforward guides and feedback sensors for maintainability, architecture fitness, and behaviour, including when each sensor runs.
*   A documented tool decision matrix classifies Ruby latest, Vernier, ZJIT/YJIT, DevSecOps workflows, Kamal, Bundler/test parallelization, Brakeman, Bearer, Dawnscanner, bundler-audit, Solid Queue/Cache/Cable, Syntax Tree, Herb, RBS/Steep, Sorbet, rbs-inline, dry-validation, PBT, Mutant, Cuprite/Playwright, Rack::Attack, and Turnstile-style bot challenges as adopted, piloted, deferred, or rejected.
*   CI includes visible jobs for parallelized RSpec, RuboCop, Brakeman, dependency audit, and at least one SARIF-capable security scanner.
*   Ruby production and experimental lanes are documented, with a compatibility report for the current latest Ruby series.
*   Vernier profiling can be run reproducibly against representative bot-traffic workloads.
*   Turnstile-style challenge escalation is feature-flagged, server-side validated, tested, and documented with bypass and rollback behavior.
*   dry-validation contracts protect selected external input boundaries without replacing ActiveRecord persistence validations.
*   At least one critical bot-control component has property-based tests and mutation testing evidence.
*   The Rails 8 Solid Trifecta and Kamal are evaluated through decision records before any migration is accepted.
*   Operator documentation explains new commands, CI gates, profiling workflow, and emergency disablement.
*   No scanner, test, benchmark, type-check, architecture, accessibility, or manual-review finding remains accepted as low risk without verified mitigation and tracked follow-up.

## 6. Out of Scope
*   Replacing the existing Sustainability Suite track.
*   Immediate wholesale migration from Sidekiq/Redis/Memcached to Rails Solid components.
*   Requiring Ruby 4.0 or ZJIT in production before compatibility and benchmark evidence exists.
*   Site-wide CAPTCHA or challenge enforcement.
*   Cloud-provider WAF configuration.
*   Mass repository formatting.
*   Full-codebase static typing in a single track.
