# Track Specification - Sustainability Suite for Scraper Traffic

## 1. Overview
The goal of this track is to implement a robust, high-performance "Sustainability Suite" that manages high-volume scraper and bot traffic. By using Rack::Attack middleware, controller header injections, a dedicated status API, and Sidekiq background queues, we protect the Alaveteli platform from Layer 7 exhaustion. Additionally, we establish caching and bulk extraction standards to coordinate efforts with the `fyi-cli` client-side tool, minimizing server strain.

## 2. Functional Requirements

### 2.1 Rack::Attack Middleware & Resiliency
*   **Token-Based Tiers:**
    *   `verified_bot` tier: Authenticated by checking the `X-FYI-Bot-Token` header. Limit set to 100 requests per minute.
    *   `anonymous` tier: Applied to all other traffic. Limit set to 10 requests per minute.
*   **Fail2Ban:**
    *   Automatically ban an IP address for 10 minutes if it triggers 5 or more `429 Too Many Requests` responses within 60 seconds.
*   **Redis Backend with Circuit-Breaker:**
    *   Configure Rack::Attack to use Redis as its caching and rate-limiting store.
    *   If Redis is unreachable or slow, the middleware must fail-open (pass requests through or use local memory rate-limiting) instead of raising 500 errors.
*   **Dynamic Load-Based Rate Limits:**
    *   Under high system load (high CPU usage or Sidekiq queue depth > 100), dynamically lower the anonymous rate limit from 10rpm to 2rpm.

### 2.2 Traffic Control Headers & Controller Concern
*   Create a controller concern `app/controllers/concerns/traffic_control.rb` to inject standard RFC back-pressure headers in all responses:
    *   `RateLimit-Limit`: The total request limit in the current window.
    *   `RateLimit-Remaining`: The remaining capacity in the current window.
    *   `RateLimit-Reset`: The number of seconds until the current rate-limit window resets.
*   **Advisory Back-Off:**
    *   When system degradation is detected, inject `X-Advisory-Status: degraded` and `Retry-After: 60` headers, prompting polite clients to temporarily back off.
*   **Standard HTTP Caching Headers:**
    *   Inject `ETag` and `Last-Modified` headers for public requests and directories. Ensure conditional `GET` requests (`If-None-Match`/`If-Modified-Since`) bypass rendering and return `304 Not Modified` when content is unchanged.

### 2.3 API Rate Limit Status & Bulk Extraction
*   Implement a JSON endpoint `/api/v1/rate_limit` returning the requester's real-time rate limits and degradation status.
*   **Bulk/Archive Extraction Standard:**
    *   Implement `/api/v1/bulk_export` to output requests/responses in NDJSON format. This avoids scraper pagination strain by sending compressed data in a single stream.

### 2.4 Traffic Prioritization & Sidekiq Queue Offloading
*   Implement `LowPriorityWorker` concern:
    *   Offload expensive unverified scraper/bot operations (e.g. search) to a `bulk_processor` Sidekiq queue to keep the real-time web thread pool responsive.

### 2.5 Cross-Repo Coordination (fyi-cli Integration)
*   Ensure `fyi-cli` (Python/Rust client-side tool) adopts the following standards:
    1.  **Rate-Limit Awareness:** Respect `RateLimit-*` and `Retry-After` headers; implement exponential back-off when receiving 429s or `X-Advisory-Status: degraded`.
    2.  **ETag/Cache Support:** Store local response ETags and send `If-None-Match` on subsequent runs to prevent redundant server-side database and rendering operations.
    3.  **Bulk Mode:** Query the `/api/v1/bulk_export` endpoint for large synchronization runs instead of scraping paginated HTML.

### 2.6 Orchestration Updates
*   Define a `simulate-attack` task in `conductor.json` to verify the Rack::Attack, Fail2Ban, and back-pressure logic locally.

## 3. Non-Functional Requirements
*   **Performance:** Rate-limiting overhead must remain under 5ms.
*   **Security:** Cryptographically secure bot tokens stored as environment variables.
*   **Quality & Style:** 100% compliance with RuboCop, Brakeman, and the Ruby on Rails Style Guide.

## 4. Acceptance Criteria
*   An IP exceeding 10 requests/minute without a valid token receives a `429 Too Many Requests` status code.
*   An IP with a valid `X-FYI-Bot-Token` header can make up to 100 requests/minute.
*   If an IP triggers 5 `429` errors in 60 seconds, it is blocked for the next 10 minutes.
*   Responses include standard rate-limiting and ETag caching headers.
*   API client hitting `/api/v1/rate_limit` gets a valid JSON payload matching their rate-limiting state.
*   Under high system load, responses contain `X-Advisory-Status: degraded` and `Retry-After`.
*   Friendly CLI requests using `If-None-Match` return `304 Not Modified` when content is unchanged.
*   Scrapers can perform bulk exports using `/api/v1/bulk_export`.
*   Expensive scraper operations are successfully dispatched to the `bulk_processor` Sidekiq queue.

## 5. Out of Scope
*   Dynamic bot token registration UI.
*   Integrating external cloud provider firewalls (WAFs).
