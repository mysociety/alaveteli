# Bot Traffic Resilience Modernization - CI Developer Documentation

This document explains the locally runnable commands that match the GitHub Actions CI pipelines, alongside expected triage procedures for test or scan failures.

## 1. Matching Local Commands

To run linter, security, dependency, and test checks locally:

### 1.1 Style and Lint checks
```bash
bundle exec rubocop
```

### 1.2 Security Scan (Brakeman)
```bash
bundle exec brakeman --fail-on-warn
```

### 1.3 Dependency Vulnerability Scan (bundler-audit)
```bash
gem install bundler-audit
bundle-audit check --update
```

### 1.4 Automated Tests (RSpec)
*   **Core Suite:**
    ```bash
    bundle exec rspec
    ```
*   **Nested Gems Suite:**
    ```bash
    bundle exec rspec gems/*/spec
    ```

---

## 2. CI Triage Flow

### 2.1 Brakeman Failures
1.  Inspect the warning details (e.g., SQL Injection, Remote Code Execution, Cross-Site Scripting).
2.  If the warning is valid:
    *   Apply proper mitigations (e.g. parameterize query, sanitize input).
3.  If the warning is a false positive:
    *   Run `bundle exec brakeman -I` to interactively ignore the warning, saving the result into `config/brakeman.ignore`.
    *   Do **not** accept any security risk as "low risk" without an ignore definition or mitigation control.

### 2.2 Bearer Failures
1.  Check the SARIF report or Bearer output in GHA.
2.  Add ignore annotations directly in code or in `bearer.yml` configuration if a finding is confirmed a false positive.

### 2.3 Dependency Audit Failures
1.  If `bundler-audit` or `dependency-review` reports a vulnerability:
    *   Run `bundle update <gem_name>` to update the gem to a patched version.
    *   If no patched version exists, configure a mitigation or follow up task immediately.
