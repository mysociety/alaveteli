# Bot Traffic Resilience Modernization - Benchmark Baseline

This document records the baseline metrics and fixtures for testing rate limits, caching, and background job operations under load.

## 1. Workload Scenarios
1.  **Public Request Page:** Simulates direct, rapid reading of request archives.
2.  **Public Body Search:** Simulates heavy search queries on public directories.
3.  **API Rate Limit Checker:** `/api/v1/rate_limit` endpoint hits.
4.  **API Bulk NDJSON Exporter:** `/api/v1/bulk_export` streaming hits.
5.  **Sidekiq Throttled Processor:** Measures latency of crawler-originated jobs processed under `bulk_processor` queue vs. default queue latency.

## 2. Dynamic Throttling Simulation Settings
*   **Normal Throttling:** 10rpm per anonymous IP.
*   **Distress Throttling:** Drops to 2rpm per anonymous IP when active Sidekiq queue depth exceeds 100 jobs.
*   **Fail2Ban Trigger:** Blocked for 10 minutes (600s) upon reaching 5 throttle status (429) events in 60 seconds.

## 3. Metrics Log
*   Benchmark scripts reside under `scripts/simulate_attack.sh` and are executed via `conductor.json`.
