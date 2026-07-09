# Phase 3 Security and Regression Gate

## Local Gate Availability

- `git diff --check`: available and clean for the Phase 3 harness and
  dependency remediation changes.
- `ruby`, `bundle`, and `docker`: unavailable on this workstation session, so
  local RSpec, RuboCop, Brakeman, bundler-audit, and benchmark execution cannot
  provide trustworthy results here.
- GitHub Actions on `edithatogo/alaveteli` is the active executable feedback
  sensor for RSpec, Brakeman, Bearer, and bundler-audit.

## CI Findings

- CI exposed two request specs requiring `rails_helper`, which does not exist in
  this repo. The specs now require the repo-standard `spec_helper`.
- The Brakeman job attempted `bundle exec brakeman` without Brakeman in the
  bundle. The workflow now installs Brakeman explicitly before running it.
- bundler-audit exposed known dependency advisories. `crass` and
  `websocket-driver` were remediated with patch-level lockfile updates.
- Remaining dependency advisories for `bootstrap-sass`, `jquery-ui-rails`, and
  `webrick` are not accepted as low risk. They are blocking closeout in
  fork-local GitHub issue `#18`.
- Brakeman now runs in warning-fail mode and emits plain text to CI logs. It
  reports 37 warnings after the existing ignore file is applied, including
  high-confidence unsafe reflection and SQL injection findings. These are not
  accepted as low risk and block closeout in fork-local GitHub issue `#19`.

## Closeout Rule

Do not mark Phase 3 complete and do not archive this track until:

- supported Ruby 3.4 CI is green for the export changes;
- Brakeman and Bearer are green or have verified false positives with
  deterministic controls;
- `bundle-audit check --update` is green with zero findings;
- the benchmark command is executable in a Ruby environment or a documented CI
  sensor replaces the unavailable local run.
