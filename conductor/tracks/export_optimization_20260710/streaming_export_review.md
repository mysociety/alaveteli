# Streaming Export Sensor Review

## Performance Sensor

The benchmark harness now supports both:

- `BULK_EXPORT_BENCHMARK_MODE=active_record`
- `BULK_EXPORT_BENCHMARK_MODE=streamer`

Both modes emit rows, bytes, elapsed seconds, SQL count, allocated objects, and
GC runs. The service spec also checks that the optimized path builds through a
`public_bodies` join, which protects against reintroducing per-row public body
association lookups.

## SQL Safety

User-controlled values are limited to:

- `limit`
- `since`

`limit` is validated as an integer greater than zero by `BulkExportContract`.
`since` is validated as a timestamp by `BulkExportContract` and parsed before
being passed to the streamer from the controller.

The streamer applies both values through ActiveRecord relation APIs:

- `limit(page_limit)`
- `where('info_requests.updated_at >= ?', since)`
- `where('info_requests.id > ?', last_id)`

The final `to_sql` string is generated from a relation after bind-safe clauses
are applied. The only string interpolation in the select list is the fixed,
internal status expression; it does not contain user-controlled data.

## Metrics and Runbooks

The endpoint-level telemetry added in the bot resilience track still applies:

- `bot_traffic_bulk_export_requests_total`
- `bot_traffic_bulk_export_unauthorized_total`

This task does not change metric names or operator actions. No runbook update is
required beyond using the benchmark command for before/after export evidence.
