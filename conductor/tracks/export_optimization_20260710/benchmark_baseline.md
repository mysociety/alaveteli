# Bulk Export Benchmark Baseline

## Command

Run from the repository root in a Ruby-enabled environment:

```bash
BULK_EXPORT_BENCHMARK_LIMIT=1000 \
bundle exec rails runner scripts/bulk_export_benchmark.rb
```

Optional inputs:

- `BULK_EXPORT_BENCHMARK_LIMIT`: maximum rows to serialize. Default: `1000`.
- `BULK_EXPORT_BENCHMARK_SINCE`: optional timestamp parsed by `Time.zone`.
- `BULK_EXPORT_BENCHMARK_MODE`: benchmark mode. Default: `active_record`.

## Metrics

The command emits JSON with:

- `rows`
- `bytes`
- `elapsed_seconds`
- `sql_count`
- `allocated_objects`
- `gc_runs`

## Baseline Policy

Phase 1 establishes the executable feedback sensor. Phase 2 must compare the
streaming implementation against `BULK_EXPORT_BENCHMARK_MODE=active_record`
using the same limit and seed data.

The benchmark cannot currently be run on this workstation because `ruby` and
`bundle` are not available on `PATH`. That is an execution blocker for local
numeric evidence, not an accepted quality risk; CI or a Ruby-enabled shell must
run the command before production rollout.
