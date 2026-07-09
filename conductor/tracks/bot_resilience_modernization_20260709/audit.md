# Bot Traffic Resilience Modernization - Baseline & State Audit

## 1. Context and Goals
This document records the baseline state of the Alaveteli platform's runtime, libraries, CI/CD setup, security scanning, and deployment configuration before implementing Phase 2 of the Modernization track.

## 2. Current State Inventory

### 2.1 Software & Framework Versions
*   **Ruby:** `3.4.7` (documented in `.ruby-version.example`)
*   **Rails:** `~> 8.0.5` (defined in `Gemfile`)
*   **Rack::Attack:** Configured in `config/initializers/rack_attack.rb` for IP rate-limiting, Fail2Ban, and dynamic load-based throttling.
*   **Background Jobs:** Sidekiq (defined in `docker-compose.yml` and `Gemfile`).
*   **Caching & Session Storage:** Redis (used for Rack::Attack rate-limiting and Sidekiq) and Memcached.

### 2.2 DevSecOps and CI Pipeline
*   **GitHub Actions:**
    *   `.github/workflows/ci.yml`: Performs checkout, cache mapping, packages installation, db configuration, core tests (`rspec`), nested gems tests (`rspec gems/*/spec`), and Coveralls coverage reports.
    *   `.github/workflows/rubocop.yml`: Configured to run RuboCop with Ruby 3.2.
*   **Static Scanners:** RuboCop is integrated into CI via reviewdog, but Brakeman and Bearer are not currently mapped to block PRs or upload SARIF reports.

### 2.3 Deployment Infrastructure
*   Configured for systemd/classic production environments.
*   Docker Compose configuration defined locally (`docker-compose.yml`) for development and testing.

## 3. Scope of Modernization Work
*   **Runtime:** Upgrading Ruby to latest 3.4.x patch, adding Ruby 4.0 experimental lane, benchmarking JIT modes (YJIT/ZJIT).
*   **DevSecOps:** Brakeman, Bearer, bundler-audit, and dependency-review setup.
*   **Throttling:** Turnstile challenges for suspicious traffic.
*   **Contracts:** dry-validation rules for boundaries.
*   **Assurance:** RBS/Steep, property-based testing (PBT), Mutant, Cuprite, and Syntax Tree.
