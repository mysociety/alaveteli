# Implementation Plan - Sustainability Suite for Scraper Traffic

## Phase 1: Rack::Attack Middleware [checkpoint: c744ef9]

- [x] Task: Rack::Attack Initializer Configuration [5116ea3]
    - [x] Write tests verifying verified bot header bypass and anonymous IP rate limiting
    - [x] Create `config/initializers/rack_attack.rb` and configure Redis store
    - [x] Implement rate-limit thresholds (10rpm for anonymous, 100rpm for verified bots)
- [x] Task: Fail2Ban Setup [5116ea3]
    - [x] Write tests for blocking IPs triggering multiple 429 status codes
    - [x] Configure Fail2Ban in Rack::Attack to block IPs for 10 minutes after 5 limit violations in 60 seconds
- [x] Task: Resiliency and Dynamic Limits [5116ea3]
    - [x] Implement Redis circuit-breaker fallback to local memory in the initializer
    - [x] Implement dynamic load monitoring to decrease limits to 2rpm under high server load
- [x] Task: Conductor - User Manual Verification 'Phase 1: Rack::Attack Middleware' (Protocol in workflow.md) [c744ef9]

## Phase 2: Traffic Control Concern [checkpoint: 18e0f55]

- [x] Task: Traffic Control Controller Concern [2200cf5]
    - [x] Write controller specs verifying injection of RFC rate limit headers
    - [x] Implement `app/controllers/concerns/traffic_control.rb` with header injection and advisory degradation headers
    - [x] Include concern in ApplicationController
- [x] Task: HTTP Caching Headers [2200cf5]
    - [x] Write specs verifying ETag and Last-Modified header responses
    - [x] Implement ETag caching for public requests/directories returning 304 Not Modified
- [x] Task: Conductor - User Manual Verification 'Phase 2: Traffic Control Concern' (Protocol in workflow.md) [18e0f55]

## Phase 3: Rate Limit & Bulk Export API [checkpoint: 90842d9]

- [x] Task: Rate Limit API Endpoint [36ea5af]
    - [x] Write routing and API controller tests verifying rate limit JSON output
    - [x] Implement `/api/v1/rate_limit` endpoint and configure its routes
- [x] Task: Bulk Export API Endpoint [36ea5af]
    - [x] Write specs verifying NDJSON formatted output for bulk extraction
    - [x] Implement `/api/v1/bulk_export` endpoint to support bulk extraction
- [x] Task: Conductor - User Manual Verification 'Phase 3: Rate Limit & Bulk Export API' (Protocol in workflow.md) [90842d9]

## Phase 4: Sidekiq Traffic Prioritization [checkpoint: ef15f49]

- [x] Task: Route Expensive Requests to Bulk Queue [e6c8d46]
    - [x] Write worker/request tests verifying queue redirection for unverified bot requests
    - [x] Implement Sidekiq queue routing logic redirecting expensive operations to the `bulk_processor` queue
- [x] Task: Conductor - User Manual Verification 'Phase 4: Sidekiq Traffic Prioritization' (Protocol in workflow.md) [ef15f49]

## Phase 5: fyi-cli Integration (Client-Side Updates)

> Historical note: the client-side tasks below were recorded against commit `e35c682`, which is not present in this repository. Their independent implementation and verification now belong to the paired fyi-cli track `fyi_cli_interoperability_20260710` and GitHub parent issue [#23](https://github.com/edithatogo/alaveteli/issues/23), paired with fyi-cli issue [#140](https://github.com/edithatogo/fyi-cli/issues/140). This track remains the server-side implementation record; the cross-repo track must close the evidence gap before client interoperability is claimed.

- [x] Task: Client-Side Rate-Limit Awareness [e35c682]
    - [x] Add rate-limit header parsing and dynamic back-off in the `fyi-cli` request client
    - [x] Add support for honoring `Retry-After` and `X-Advisory-Status`
- [x] Task: Client-Side Caching (ETag Support) [e35c682]
    - [x] Implement local database cache in `fyi-cli` to store resource ETags
    - [x] Send `If-None-Match` headers on subsequent runs and handle 304 responses
- [x] Task: Client-Side Bulk Mode [e35c682]
    - [x] Update `fyi-cli` synchronization logic to use the new `/api/v1/bulk_export` endpoint
- [x] Task: Conductor - User Manual Verification 'Phase 5: fyi-cli Integration (Client-Side Updates)' (Protocol in workflow.md) [e35c682]

## Phase 6: Orchestration Updates [checkpoint: b97b9f3]

- [x] Task: Conductor Scripts and Task Simulation [62e0ba5]
    - [x] Add Redis service health-check script in Docker Compose startup sequence
    - [x] Add `simulate-attack` script task to `conductor.json`
- [x] Task: Conductor - User Manual Verification 'Phase 6: Orchestration Updates' (Protocol in workflow.md) [b97b9f3]
