# Bot Traffic Resilience Modernization - Tool Recommendations Decision Record

This document records the architectural classifications (Adopt, Pilot, Defer, Reject) for tools and frameworks proposed during the Bot Traffic Resilience Modernization program.

## 1. Classifications

### 1.1 Adopt
*   **Ruby 3.4.x (Latest):** Upgrading the main production lane to the latest safe patch of 3.4 to leverage runtime improvements.
*   **Vernier:** Adopted for precise multithreaded profiling of web requests and bulk processors.
*   **Brakeman:** First-class CI gate blocking PRs on any security vulnerability warnings.
*   **bundler-audit:** Adopted to detect vulnerable gems in Gemfile lockfiles.
*   **GitHub Dependency Review:** Adopted to scan incoming PRs for dependency supply-chain risks.

### 1.2 Pilot
*   **Ruby YJIT:** Pilot for production workload benchmarking.
*   **Bearer Security Scanner:** Pilot for static code security scanning with SARIF reporting.
*   **RBS + Steep / rbs-inline:** Pilot type safety on new traffic control, contracts, and serializers to evaluate developer overhead.
*   **dry-validation:** Pilot input contract checking on external endpoints and rate-limit boundaries.
*   **Property-Based Testing (PBT):** Pilot using Rantly/similar to test ETag and rate-limit invariants.
*   **Mutant (Mutation Testing):** Pilot on select pure core utility classes.
*   **Cuprite:** Pilot for headless Capybara integration testing to avoid system-level selenium setup.
*   **Turnstile:** Pilot feature-flagged challenge validation for high-risk IPs.

### 1.3 Defer
*   **Ruby ZJIT:** Deferred due to early state and lack of stability data.
*   **Rails Solid Trifecta (Queue, Cache, Cable):** Deferred; keep existing Sidekiq, Redis, and Memcached infrastructure until benchmark comparison yields clear operational simplicity/performance benefits.
*   **Kamal:** Deferred until an operator-driven deployment configuration requirement is finalized.
*   **Sorbet:** Deferred in favor of Steep/RBS.

### 1.4 Reject
*   **Dawnscanner:** Rejected as redundant alongside Brakeman and Bearer.
*   **Mass Formatting:** Rejected to prevent massive git blame noise across legacy codebase.
*   **Broad Turnstile Challenges:** Rejected; Turnstile must remain targeted and feature-flagged only.
