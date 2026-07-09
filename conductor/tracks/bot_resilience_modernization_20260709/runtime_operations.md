# Bot Traffic Resilience Modernization - Runtime Operations and Rollback

This runbook outlines settings, environment flags, and rollback procedures for Ruby JIT modes, profiling, and runtime upgrades.

## 1. Ruby JIT Modes

### 1.1 YJIT
YJIT is the recommended JIT compiler for production Rails workloads under Ruby 3.4+.
*   **Enabling YJIT:** Set environment variable `RUBY_YJIT_ENABLE=1` or run ruby command with `--yjit` flag.
*   **Disabling YJIT:** Unset `RUBY_YJIT_ENABLE` or run ruby without the flag.

### 1.2 ZJIT
ZJIT is currently experimental and should **not** be enabled in production.
*   **Enabling ZJIT:** Run ruby with `--zjit` flag.

## 2. Vernier Profiling
To capture active request profiling under high scraper load:
1.  Run the profile runner script:
    `bundle exec ruby scripts/profile_runner.rb <workload_name>`
2.  Traces are output to `tmp/profiles/` as JSON files.
3.  Open the JSON profiles using Speedscope or equivalent Chrome DevTools performance viewer.

## 3. Rollback Procedures
*   **Ruby version fallback:** Revert the matrix change in `.github/workflows/ci.yml` and `.github/workflows/rubocop.yml`. No database migrations or persistent storage actions are required.
*   **Vernier profiling removal:** Remove `gem 'vernier'` from Gemfile, run `bundle install`, and delete `scripts/profile_runner.rb`.
