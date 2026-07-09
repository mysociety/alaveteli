# Bot Traffic Resilience Modernization - Challenge and Contract Operations

This runbook outlines settings, feature flags, metrics, and rollback procedures for Turnstile challenges and dry-validation contracts.

## 1. Turnstile Challenges

### 1.1 Activation and Configuration
Turnstile challenges are feature-flagged and can be enabled or disabled via environment variables:
*   `TURNSTILE_ENABLED`: Set to `true` to enable security verification challenge pages for suspicious requests.
*   `TURNSTILE_SITE_KEY`: The Cloudflare site key used by the widget.
*   `TURNSTILE_SECRET_KEY`: The Cloudflare secret key used for siteverify verification.

### 1.2 Bypassing / Disabling
If false positives occur:
1.  **Instant Disable:** Set `TURNSTILE_ENABLED=false` in the production environment settings.
2.  **Verified Bot Bypass:** Verified bots with a valid token header `X-FYI-Bot-Token` bypass challenges automatically.

## 2. Dry-Validation Contracts
Inputs to external endpoints `/api/v1/rate_limit` and `/api/v1/bulk_export` are checked using schemas located under `app/contracts/`. Invalid inputs are rejected with `422 Unprocessable Entity` responses.
