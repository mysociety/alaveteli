# Bot Traffic Resilience Modernization - Rollout, Monitoring, and Incident Runbook

This document details the telemetry metrics, privacy considerations, operational incident procedures, and final verification checklists for the modernization program.

## 1. Metrics & Monitoring Telemetry
To monitor bot traffic and rate-limiting effectively, the following metrics are exposed/tracked:
*   `rate_limit.decision`: Count of allowed vs. throttled (429) requests, split by anonymous and verified bot tiers.
*   `challenge.issued`: Count of Turnstile security challenges presented to suspicious anonymous traffic.
*   `challenge.passed` / `challenge.failed`: Challenge validation outcomes.
*   `cache.hit_rate`: Ratio of ETag cache hits (304 Not Modified) vs. full renders (200 OK).
*   `bulk_export.count`: Volume of metadata stream requests from verified bots.

## 2. Privacy & Accessibility Considerations
*   **Privacy:** Turnstile is privacy-preserving compared to traditional CAPTCHAs. It does not harvest personal details or track users across non-Cloudflare sites. Telemetry logs must hash IP addresses and avoid storing user-agent metadata long-term.
*   **Accessibility:** Turnstile does not require interactive puzzle solving, making it highly compatible with screen readers and assistive technologies. Bypasses are provided for verified automated agents and API consumers.

## 3. Incident Runbook

### 3.1 Scenario: Sudden Layer 7 Scraper Spike
1.  **Check metrics:** Inspect active connections and the ratio of 429 status codes.
2.  **Enable Turnstile challenges:** If anonymous rate limits are insufficient to protect the server, set `TURNSTILE_ENABLED=true` in the environment to escalate verification checks.
3.  **Purge Sidekiq Queue:** If the `bulk_processor` queue grows excessively large, scale workers or prune crawler tasks:
    ```bash
    # Purge bulk_processor queue in Sidekiq
    Sidekiq::Queue.new("bulk_processor").clear
    ```

### 3.2 Scenario: Turnstile Outage or High False Positives
1.  If Cloudflare Turnstile experiences downtime or is blocking legitimate users:
    *   Set `TURNSTILE_ENABLED=false` to disable challenges immediately.
    *   Restart the web workers to apply the setting.
