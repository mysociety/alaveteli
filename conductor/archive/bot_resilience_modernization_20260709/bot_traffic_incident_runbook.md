# Bot Traffic Incident Runbook

This runbook is the Phase 7 operator guide for high bot or scraper pressure.

## Signals

Use `/health/metrics.txt` and application logs as the first feedback sensors.

Key metrics:

- `bot_traffic_rate_limit_requests_total`
- `bot_traffic_bulk_export_requests_total`
- `bot_traffic_bulk_export_unauthorized_total`
- `bot_traffic_challenge_issued_total`
- `bot_traffic_challenge_passed_total`
- `bot_traffic_challenge_failed_total`
- `bot_traffic_turnstile_enabled`
- `bot_traffic_turnstile_configured`
- `bot_traffic_verified_bot_token_configured`
- `sidekiq_enqueued_jobs`
- `sidekiq_default_queue_latency_seconds`
- `xapian_queued_jobs`

## Triage

1. Confirm whether the pressure is anonymous HTML traffic, verified bot API traffic, bulk export traffic, or background queue pressure.
2. Check `RateLimit-*`, `Retry-After`, and `X-Advisory-Status` response headers for affected requests.
3. Compare challenge pass and fail counters. A high fail rate may indicate abusive automation; a high issue rate with a low pass rate may indicate false positives or provider trouble.
4. Check Sidekiq queue latency before adding more web-facing controls.
5. Review recent deploys and scanner findings. Do not accept low severity findings as operationally harmless without mitigation.

## Controls

Use controls in this order:

1. Confirm verified clients are using the bot token and bulk export endpoint.
2. Tune Rack::Attack limits for anonymous traffic.
3. Enable degraded advisory headers when queue pressure is high.
4. Enable `TURNSTILE_ENABLED=true` only when softer controls are insufficient.
5. Disable Turnstile immediately if accessibility, provider, or false-positive issues affect legitimate FOI users.

## Rollback

Turnstile:

1. Set `TURNSTILE_ENABLED=false`.
2. Verify `bot_traffic_turnstile_enabled 0` in `/health/metrics.txt`.
3. Confirm normal request pages and request creation paths work without a challenge.

Bulk export:

1. Rotate `FYI_BOT_TOKEN` if token misuse is suspected.
2. Verify `bot_traffic_verified_bot_token_configured 1` after rotation.
3. Ask verified clients to retry with backoff and `If-None-Match` support where available.

Profiling:

1. Capture Vernier profiles before and after any runtime/JIT change.
2. Keep profile outputs in `tmp/profiles/`; do not commit raw profiles unless redacted and intentionally sampled.

## Privacy and Accessibility

- Do not store IP addresses in metric names or labels.
- Do not add high-cardinality metrics for user IDs, request IDs, tokens, or raw paths.
- Challenge flows must remain disabled by default and must have a tested rollback path.
- Legitimate FOI access takes priority over bot friction when controls are ambiguous.

## Harness Follow-Up

After every incident:

1. Add or update a Conductor task for any unresolved risk.
2. Add a deterministic sensor for repeated failures where practical.
3. Update this runbook if an operator had to rely on undocumented knowledge.
