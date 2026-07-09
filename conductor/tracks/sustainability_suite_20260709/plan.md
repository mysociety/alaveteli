# Implementation Plan - Sustainability Suite for Scraper Traffic

## Phase 1: Rack::Attack Middleware

- [ ] Task: Rack::Attack Initializer Configuration
    - [ ] Write tests verifying verified bot header bypass and anonymous IP rate limiting
    - [ ] Create `config/initializers/rack_attack.rb` and configure Redis store
    - [ ] Implement rate-limit thresholds (10rpm for anonymous, 100rpm for verified bots)
- [ ] Task: Fail2Ban Setup
    - [ ] Write tests for blocking IPs triggering multiple 429 status codes
    - [ ] Configure Fail2Ban in Rack::Attack to block IPs for 10 minutes after 5 limit violations in 60 seconds
- [ ] Task: Conductor - User Manual Verification 'Phase 1: Rack::Attack Middleware' (Protocol in workflow.md)

## Phase 2: Traffic Control Concern

- [ ] Task: Traffic Control Controller Concern
    - [ ] Write controller specs verifying injection of RFC rate limit headers
    - [ ] Implement `app/controllers/concerns/traffic_control.rb` with header injection and advisory degradation headers
    - [ ] Include concern in ApplicationController
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Traffic Control Concern' (Protocol in workflow.md)

## Phase 3: Rate Limit Status API

- [ ] Task: Rate Limit API Endpoint
    - [ ] Write routing and API controller tests verifying rate limit JSON output
    - [ ] Implement `/api/v1/rate_limit` endpoint and configure its routes
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Rate Limit Status API' (Protocol in workflow.md)

## Phase 4: Sidekiq Traffic Prioritization

- [ ] Task: Route Expensive Requests to Bulk Queue
    - [ ] Write worker/request tests verifying queue redirection for unverified bot requests
    - [ ] Implement Sidekiq queue routing logic redirecting expensive operations to the `bulk_processor` queue
- [ ] Task: Conductor - User Manual Verification 'Phase 4: Sidekiq Traffic Prioritization' (Protocol in workflow.md)

## Phase 5: Orchestration Updates

- [ ] Task: Conductor Scripts and Task Simulation
    - [ ] Add Redis service health-check script in Docker Compose startup sequence
    - [ ] Add `simulate-attack` script task to `conductor.json`
- [ ] Task: Conductor - User Manual Verification 'Phase 5: Orchestration Updates' (Protocol in workflow.md)
