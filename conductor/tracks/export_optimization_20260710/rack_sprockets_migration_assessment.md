# Rack/Sprockets Migration Assessment

## Current constraint

The current asset and server dependency path resolves:

- `rack` 2.2.x
- `sprockets` 3.7.x, which requires Rack `< 3`
- `sass-rails` 5.x, which requires Sprockets `< 4`
- `rackup` 1.x, which brings `webrick`

An isolated `rack ~> 3.2` resolver test failed because the current Sprockets
constraint requires Rack `< 3`. This rules out a one-line Rack or rackup PR.

## Candidate paths

### Path A: Sprockets 4 compatibility first

Replace the legacy Sass integration with a Sprockets-4-compatible Sass path,
preserve Rack 2 temporarily, and prove asset behavior. This improves the asset
boundary but does not remove the WEBrick dependency by itself.

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
