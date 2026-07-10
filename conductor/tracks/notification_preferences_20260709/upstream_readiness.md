# Notification Preferences Upstream Readiness

## Fork-Local Delivery

- Parent issue: `#20` Prepare notification preferences for upstream review.
- Focused subissue: `#21` Build and verify isolated notification-preferences
  candidate.
- Draft PR: `#22` Add user notification preferences.
- Baseline branch: `upstream-develop-baseline`, pinned from
  `mysociety/develop` at `328711a01`.
- Candidate branch: `notification-preferences-upstream-ready`.
- No upstream issue or PR has been created.

## Candidate Scope

The candidate contains only notification-preference migration, model,
controller, route, profile navigation, settings view, mailer behavior,
changelog, and focused tests. It excludes Conductor, bot resilience, bulk
export, dependency modernization, and unrelated CI changes.

## Findings Resolved

- Added profile navigation so authenticated users can discover the settings.
- Replaced manual Boolean casting with strong-parameter model updates, which
  preserves omitted values during partial updates.
- Made authenticated-user ownership explicit in the controller.
- Eager-loaded notification users to prevent a newly introduced N+1 query.
- Added the upstream-required changelog entry and conformed new lines to the
  upstream RuboCop policy.

## Verification Evidence

- `git diff --check upstream/develop...HEAD`: pass.
- Changelog PR gate: pass.
- RuboCop PR gate: pass.
- Brakeman baseline-delta harness: pass, zero new candidate fingerprints.
- Dependency manifest delta: pass, `Gemfile` and `Gemfile.lock` unchanged.
- Supported Ruby 3.4 full suite: in progress.
- Local Ruby, Bundler, and Docker remain unavailable on this workstation.

The track remains in progress until supported CI is green and the final risk
review confirms that no known risk remains.
