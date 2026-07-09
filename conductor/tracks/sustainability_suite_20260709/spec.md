# Track Specification - Sustainability Suite for Scraper Traffic

## 1. Overview
The goal of this track is to implement a robust, high-performance "Sustainability Suite" that manages high-volume scraper and bot traffic. By using Rack::Attack middleware, controller header injections, a dedicated status API, and Sidekiq background queues, we protect the Alaveteli platform from Layer 7 exhaustion while enabling friendly third-party tools (like `edithatogo/fyi-cli`) to coordinate and pace their requests.

## 2. Functional Requirements

### 2.1 Rack::Attack Middleware
*   **Token-Based Tiers:**
    *   `verified_bot` tier: Authenticated by checking the `X-FYI-Bot-Token` header. Limit set to 100 requests per minute.
    *   `anonymous` tier: Applied to all other traffic. Limit set to 10 requests per minute.
*   **Fail2Ban:**
    *   Automatically ban an IP address for 10 minutes if it triggers 5 or more `429 Too Many Requests` responses within 60 seconds.
*   **Redis Backend:**
    *   Configure Rack::Attack to use Redis as its caching and rate-limiting store.

### 2.2 Traffic Control Headers & Controller Concern
*   Create a controller concern `app/controllers/concerns/traffic_control.rb` to inject standard RFC back-pressure headers in all responses:
    *   `RateLimit-Limit`: The total request limit in the current window.
    *   `RateLimit-Remaining`: The remaining capacity in the current window.
    *   `RateLimit-Reset`: The number of seconds until the current rate-limit window resets.
*   **Advisory Back-Off:**
    *   When system degradation is detected (e.g. Sidekiq queue size > 100 or high server load), inject `X-Advisory-Status: degraded` and `Retry-After: 60` headers, prompting polite clients to temporarily back off.

### 2.3 Rate Limit Status API
*   Implement a new JSON endpoint `/api/v1/rate_limit` which returns the requester's current rate-limit status:
    ```json
    {
      "tier": "verified_bot" or "anonymous",
      "limit": 100,
      "remaining": 87,
      "reset_in_seconds": 32,
      "advisory_status": "nominal" or "degraded"
    }
    ```

### 2.4 Traffic Prioritization & Sidekiq Queue Offloading
*   Implement `LowPriorityWorker` concern or traffic routing:
    *   For expensive requests (e.g., search/detail lookups) coming from unverified bots, route their execution to a `bulk_processor` Sidekiq queue rather than handling them synchronously in the web thread or standard real-time queue.

### 2.5 Orchestration Updates
*   Define a `simulate-attack` task in `conductor.json` or local scripts to test the rate-limiting, Fail2Ban triggers, and back-pressure headers locally.

## 3. Non-Functional Requirements
*   **Performance:** Negligible overhead for rate-limiting checks (Redis read/write latency under 5ms).
*   **Security:** Cryptographically secure bot tokens stored as environment variables.
*   **Style:** Adhere strictly to the Ruby on Rails Style Guide.

## 4. Acceptance Criteria
*   An IP exceeding 10 requests/minute without a valid token receives a `429 Too Many Requests` status code.
*   An IP with a valid `X-FYI-Bot-Token` header can make up to 100 requests/minute.
*   If an IP triggers 5 `429` errors in 60 seconds, it is blocked with a 429 response for the next 10 minutes.
*   Every response contains the `RateLimit-Limit`, `RateLimit-Remaining`, and `RateLimit-Reset` headers.
*   API client hitting `/api/v1/rate_limit` gets a valid JSON payload matching their rate-limiting state.
*   Under high system load, responses contain `X-Advisory-Status: degraded` and `Retry-After`.
*   Expensive scraper operations are successfully dispatched to the `bulk_processor` Sidekiq queue.

## 5. Out of Scope
*   Dynamic bot token registration UI.
*   Integrating external cloud provider firewalls (WAFs).
