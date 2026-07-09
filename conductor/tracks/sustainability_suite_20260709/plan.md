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

## Phase 4: Sidekiq Traffic Prioritization

- [ ] Task: Route Expensive Requests to Bulk Queue
    - [ ] Write worker/request tests verifying queue redirection for unverified bot requests
    - [ ] Implement Sidekiq queue routing logic redirecting expensive operations to the `bulk_processor` queue
- [ ] Task: Conductor - User Manual Verification 'Phase 4: Sidekiq Traffic Prioritization' (Protocol in workflow.md)

## Phase 5: fyi-cli Integration (Client-Side Updates)

- [ ] Task: Client-Side Rate-Limit Awareness
    - [ ] Add rate-limit header parsing and dynamic back-off in the `fyi-cli` request client
    - [ ] Add support for honoring `Retry-After` and `X-Advisory-Status`
- [ ] Task: Client-Side Caching (ETag Support)
    - [ ] Implement local database cache in `fyi-cli` to store resource ETags
    - [ ] Send `If-None-Match` headers on subsequent runs and handle 304 responses
- [ ] Task: Client-Side Bulk Mode
    - [ ] Update `fyi-cli` synchronization logic to use the new `/api/v1/bulk_export` endpoint
- [ ] Task: Conductor - User Manual Verification 'Phase 5: fyi-cli Integration (Client-Side Updates)' (Protocol in workflow.md)

## Phase 6: Orchestration Updates

- [ ] Task: Conductor Scripts and Task Simulation
    - [ ] Add Redis service health-check script in Docker Compose startup sequence
    - [ ] Add `simulate-attack` script task to `conductor.json`
- [ ] Task: Conductor - User Manual Verification 'Phase 6: Orchestration Updates' (Protocol in workflow.md)
