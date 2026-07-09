# Bot Traffic Resilience Modernization - Solid Trifecta & Kamal Evaluation

This document evaluates the Rails 8 "Solid Trifecta" (Solid Queue, Solid Cache, Solid Cable) and Kamal deployment against the current Alaveteli stack.

## 1. Solid Trifecta vs. Existing Stack

### 1.1 Cache: Memcached / Redis vs. Solid Cache
*   **Current Stack:** Memcached for general caching, Redis for Rack::Attack rate-limiting counters.
*   **Solid Cache:** Stores cache entries directly in the relational database (Postgres).
*   **Evaluation:** For high-volume scraper traffic, writing rate-limiting counters to Postgres (via Solid Cache) introduces significant database write overhead and disk I/O. Redis cache is far faster and avoids database table bloat.
*   **Recommendation:** **Defer** Solid Cache for rate-limiting. Retain Redis.

### 1.2 Queue: Sidekiq + Redis vs. Solid Queue
*   **Current Stack:** Sidekiq backed by Redis.
*   **Solid Queue:** Database-backed Active Job adapter.
*   **Evaluation:** Under high crawler stress, enqueuing thousands of metadata parsing or scraping jobs in Postgres adds lock contention. Sidekiq handles high-concurrency throughput with lower CPU utilization.
*   **Recommendation:** **Defer** Solid Queue. Retain Sidekiq.

## 2. Kamal Deployment Configuration
We provide an example `config/deploy.yml` for operators who want to transition to Kamal.

### 2.1 example `config/deploy.yml`
```yaml
service: alaveteli
image: edithatogo/alaveteli

servers:
  web:
    - 192.168.1.100
  job:
    hosts:
      - 192.168.1.101
    cmd: bundle exec sidekiq

registry:
  server: ghcr.io
  username: edithatogo
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  clear:
    DB_HOST: 192.168.1.102
    REDIS_URL: redis://192.168.1.103:6379/0
  secret:
    - RAILS_MASTER_KEY
    - FYI_BOT_TOKEN
    - TURNSTILE_SECRET_KEY
```

## 3. Operations Runbook

### 3.1 Stack Selection Guide
*   **Default Stack:** Use systemd, Sidekiq, Redis, and Memcached for high-volume, production deployments.
*   **Containerized Stack:** Use Kamal for single-host or small multi-server setups that require automated Docker rollouts.

### 3.2 Rollback and Troubleshooting
*   **Deployment Rollback (Kamal):** Run `kamal rollback <version>` to instantly revert the running container.
*   **Sidekiq Failures:** Check Redis connection status using `redis-cli ping`. If Sidekiq queue lags, scale sidekiq workers or purge the `bulk_processor` queue if the lag is caused by malicious scraper traffic.
```

,Description:
