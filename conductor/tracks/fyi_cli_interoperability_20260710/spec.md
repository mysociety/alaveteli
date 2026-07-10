# Track Specification: fyi-cli Interoperability

## Outcome

Make the fork-local Alaveteli server contract explicit, deterministic, and
verifiable for fyi-cli traffic. This track coordinates with
`edithatogo/fyi-cli`; it does not create upstream issues or pull requests.

## Existing evidence and gap

The Sustainability Suite implemented server-side rate limiting, back-pressure
headers, conditional caching, rate-limit status, and NDJSON bulk export. Its
Phase 5 records fyi-cli work under commit `e35c682`, but that commit is not
present in this repository and the client implementation is maintained in the
separate fyi-cli repository. This track resolves that evidence gap without
rewriting the historical track.

## Contract surface

- `RateLimit-Limit`, `RateLimit-Remaining`, and `RateLimit-Reset`
- `Retry-After` and `X-Advisory-Status: degraded`
- `ETag`, `Last-Modified`, `If-None-Match`, and `304 Not Modified`
- `/api/v1/rate_limit`
- bounded `/api/v1/bulk_export` NDJSON responses
- `X-FYI-Bot-Token` and traceable client identity expectations

## Risk policy

No known security, privacy, availability, correctness, data-integrity, or
quality risk may be accepted. Unresolved ambiguity blocks closure or becomes a
disabled, dated follow-up with a deterministic sensor.

## Harness requirements

Every slice must add or improve feedforward guidance and a feedback sensor:
contract fixtures, request specs, security checks, bounded smoke commands,
secret-redaction assertions, and explicit rollback/disablement instructions.
Default CI remains offline; live verification is opt-in and bounded.

## Delivery boundaries

Each child issue maps to one focused PR. Server behavior changes are separate
from documentation/fixture work and separate from final cross-repo verification.

