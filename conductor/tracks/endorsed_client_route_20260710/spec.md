# Track Specification: Endorsed Client Route

## Outcome

Evaluate a server-side, explicitly opt-in route for fyi-cli and MCP clients
that a sysadmin can enable, constrain, observe, revoke, and switch off. The
purpose is to make bounded, identifiable behavior easier for ordinary clients
and reduce accidental load from clients that otherwise discover and retrieve
too much data.

This is a fork-local planning track. It does not authorize upstream changes.

## Server control requirements

- Disabled by default and fail closed on ambiguous configuration.
- Scoped authentication, identity, rotation, revocation, and allowlists.
- Per-client and instance-wide request, byte, runtime, concurrency, retry, and
  export budgets.
- Versioned capability discovery and explicit contract negotiation.
- Standard back-pressure signals, audit events, metrics, operator status,
  maintenance windows, and an emergency kill switch.
- Existing authorization, privacy, abuse prevention, and normal web/API paths
  remain authoritative.
- No anonymous privileged access, unbounded export, or remote MCP exposure by
  default.

## Evidence gate

The paired fyi-cli and Alaveteli fork tracks must agree on offline fixtures,
deterministic tests, threat model, rollback and disablement behavior,
secret-free diagnostics, and known-risk disposition before any upstream issue
is opened. Maintainer discussion must precede any upstream PR.

