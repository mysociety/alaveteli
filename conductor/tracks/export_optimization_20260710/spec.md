# Spec: Optimize Bulk Export API

## Objective

Optimize Alaveteli's bulk information request export API so verified bots can
export very large public request metadata datasets with bounded memory use,
stable ordering, and no avoidable database timeout risk.

## Scope

- Keep `GET /api/v1/bulk_export` behind the existing verified bot token.
- Keep newline-delimited JSON output and the existing field names.
- Replace per-record `InfoRequest` model instantiation with a deterministic
  streaming query path.
- Preserve `limit` and `since` contract validation.
- Add fast regression coverage that compares exported rows with the existing
  public field contract.
- Add a benchmark or profiling harness that can be run in CI or locally when
  Ruby is available.

## Non-Goals

- No schema migration.
- No new unauthenticated export endpoint.
- No change to the semantics of request visibility or moderation.
- No wholesale replacement of ActiveRecord outside this export boundary.

## Requirements

1. **Streaming Selection:** Avoid instantiating full `InfoRequest` objects for
   the export body. Use a bounded query that selects only exported columns.
2. **Stable Pagination:** Stream rows in deterministic `id` order with a
   configured maximum page size so memory stays bounded.
3. **Association Safety:** Resolve public body name and URL title with a join,
   not per-row association lookup.
4. **NDJSON Compatibility:** Keep one valid JSON object per line and preserve
   the existing keys: `id`, `title`, `url_title`, `created_at`, `updated_at`,
   `status`, `public_body_name`, and `public_body_url_name`.
5. **No SQL Injection:** Build SQL with Rails sanitization or relation APIs.
   User-controlled values must never be interpolated directly into SQL.
6. **Harness Evidence:** Add tests for token enforcement, input validation,
   since filtering, limit enforcement, and row shape. Add an operator benchmark
   command or documented script for allocation and latency comparison.

## Risk Policy

No known low-severity correctness, privacy, availability, or data-integrity
risk may be accepted. Any remaining issue must be fixed, proved false,
mitigated behind a disabled-by-default control, or recorded as a blocking
Conductor task before this track closes.
