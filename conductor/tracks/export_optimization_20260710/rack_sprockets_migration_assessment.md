# Rack/Sprockets Migration Assessment

## Current constraint

The fork currently resolves:

- `rack` 2.2.23
- `sprockets` 3.7.5, which requires Rack `< 3`
- `sass-rails` 5.0.8, which requires Sprockets `< 4`
- `rackup` 1.0.1, which brings `webrick` 1.9.2

An isolated `rack ~> 3.2` resolver test failed because `sprockets ~> 3.7.5`
requires Rack `< 3`. This rules out a one-line Rack or rackup PR.

## Candidate paths

### Path A: Sprockets 4 compatibility first

Replace the legacy Sass integration with a Sprockets-4-compatible Sass path,
preserve Rack 2 temporarily, and prove asset behavior. This improves the
asset boundary but does not remove the WEBrick dependency by itself.

### Path B: Rack 3 migration with modern Sass integration

Move the application to a Rack-3-compatible Rails/session/asset graph and use
a maintained Sass integration such as Dart Sass. This is the path that can
remove the `rackup 1.x -> webrick` edge, but it must be treated as a separate
migration with explicit boot, precompile, CSS, runtime asset-read, and request
coverage.

## Decision gate

Do not open an implementation PR until a clean resolver fixture identifies the
exact supported graph. Do not combine this work with Bootstrap or jQuery UI
upgrades, bulk-export behavior, or scanner configuration changes.

## Required sensors

- Lockfile assertion that no `webrick` dependency path remains.
- `bundle exec rails runner` boot smoke.
- `bundle exec rails assets:precompile` in supported CI.
- Existing responsive/admin asset and runtime asset-read specs.
- Focused Rails controller specs, Brakeman, dependency review, and
  `bundle-audit check --update` with zero findings.
