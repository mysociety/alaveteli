# Request states and statutory-clock extension hooks

This note documents Alaveteli's request-state model for theme authors and
downstream compliance tooling (deadline calculators, audit pipelines, FOI
process mappers). It does **not** change default UX behaviour.

Related: https://github.com/mysociety/alaveteli/issues/9355

## Two layers of "status"

| Layer | Source | Purpose |
| --- | --- | --- |
| **Described state** | `InfoRequest#described_state` | User- or admin-classified status stored on the request. Valid values: `InfoRequest::State.all`. |
| **Calculated / display status** | `InfoRequest#calculate_status` | Described state plus time-based overdue derivatives (`waiting_response_overdue`, `waiting_response_very_overdue`) and `waiting_classification` when `awaiting_description` is set. |

Public-facing labels come from `InfoRequest::State.short_description` and
`InfoRequest.get_status_description`. API consumers typically receive
`described_state` / `status` / `display_status` (see `json_for_api` and
`ApiController#show_request`).

## Canonical described states

| State | Short label | Role | Notes for statutory / process tooling |
| --- | --- | --- | --- |
| `waiting_response` | Awaiting response | **process** | Initial open state; overdue clocks derive from this via `date_response_required_by` / `date_very_overdue_after`. |
| `waiting_clarification` | Awaiting clarification | **process** | Requester has been asked to clarify; jurisdictions may pause or restart legal clocks. |
| `gone_postal` | Handled by postal mail | **process** | Offline channel; limited machine-readable evidence of process stage. |
| `internal_review` | Awaiting internal review | **process** | Appeal / internal review stage. |
| `successful` | Successful | **process** | User observation of full release; not a legal determination of grounds. |
| `partially_successful` | Partially successful | **process** | Partial release; withholding grounds live in correspondence, not state. |
| `rejected` | Refused | **process** | Internal name is historic; UI says "refused". Statutory refusal grounds are not encoded in the state value. |
| `not_held` | Information not held | **process** | Information not held (or equivalent). |
| `user_withdrawn` | Withdrawn | **process** | Requester withdrew; process ends. |
| `error_message` | Delivery error | **platform** | Mail / delivery failure — not a legal outcome. |
| `requires_admin` | Requires admin attention | **platform** | Moderation / operator queue. |
| `attention_requested` | Reported | **platform** | User reported the request for admin attention. |
| `vexatious` | Vexatious | **admin** | Admin-only classification; not set via normal user transitions. |
| `not_foi` | Not an FOI request | **admin** | Admin-only; closes as non-FOI. |

**Role** values are also available programmatically via
`InfoRequest::State.role_for(state)` / `InfoRequest::State.roles`
(`:process`, `:platform`, `:admin`, `:calculated`).

### Calculated-only statuses (not stored as `described_state`)

| Status | Role | Meaning |
| --- | --- | --- |
| `waiting_classification` | **calculated** | A response arrived and still needs classification (`awaiting_description`). |
| `waiting_response_overdue` | **calculated** | Past `date_response_required_by` while still waiting. |
| `waiting_response_very_overdue` | **calculated** | Past `date_very_overdue_after` while still waiting. |

These are produced by `calculate_status` / theme overrides and must not be
written into `described_state` by ordinary classifiers.

## What states are *not*

Alaveteli states are **user-facing observations and operator workflow labels**.
They are not:

* a jurisdiction-neutral FOI process ontology
* a store for statutory exemption / refusal grounds
* a substitute for reading correspondence when auditing legal compliance

Downstream tools that drive **statutory clocks** (working-day deadlines,
clarification pauses, internal-review timers) should treat core states as
*inputs* to a local mapping, not as authoritative legal outcomes.

## Existing theme extension: custom states

Deployments already extend the state machine via a theme `customstates` library
(loaded from `InfoRequest` when present):

```ruby
# theme lib/customstates.rb (sketch)
module InfoRequestCustomStates
  def theme_calculate_status
    # optional: jurisdiction-specific overdue / extension logic
    base_calculate_status
  end

  module ClassMethods
    def theme_extra_states
      %w[deadline_extended] # example only
    end

    def theme_display_status(status)
      # labels for extra states
    end

    def theme_short_description(status)
      # short labels for extra states
    end
  end
end
```

See `spec/models/customstates.rb` for the example mixin used in tests, and
`InfoRequest::State.all`, which merges `theme_extra_states` when loaded.

Also available for controllers: `RequestControllerCustomStates#theme_describe_state`.

## New optional hook: process / clock metadata

For compliance tooling that needs structured metadata *without* parsing message
bodies, themes may implement:

```ruby
# instance method on InfoRequest (via InfoRequestCustomStates)
def theme_process_clock_metadata
  {
    # Free-form, jurisdiction-defined keys. Examples only:
    # "process_state" => "RECEIVED",
    # "clock" => "active",           # active | paused | stopped | unknown
    # "confidence" => 0.74,
    # "legislation" => law_used,
    # "mapping_version" => "1.0"
  }
end
```

Core behaviour:

* `InfoRequest#process_clock_metadata` returns `{}` unless the theme method exists.
* When non-empty, the hash is included in `InfoRequest#json_for_api` under
  `process_clock_metadata`.
* Core does **not** validate keys or values — local deployments own the schema.
* No database column is required; themes may compute the hash from
  `described_state`, `law_used`, tags, dates, or their own tables.

This keeps UK / default WhatDoTheyKnow behaviour unchanged while giving sites
such as FYI.org.nz a stable attachment point for OIA (or other) clock tooling.

## Guidance for theme and plugin authors

1. Prefer **stable string identifiers** (`described_state` / calculated status)
   over translated labels when integrating external systems.
2. Treat `:platform` and `:admin` roles as non-legal; do not advance statutory
   clocks solely from `error_message`, `requires_admin`, etc.
3. Keep jurisdiction-specific process enums in the theme (or external service);
   map from Alaveteli states with an explicit confidence or provenance field.
4. Use existing date fields (`date_initial_request_last_sent_at`,
   `date_response_required_by`, `date_very_overdue_after`) rather than
   re-deriving deadlines from free text when possible.
5. When adding `theme_extra_states`, document whether each new state is
   process-relevant or platform-only.

## Example external mapping (informative only)

The following illustrates how one external project maps Alaveteli states for NZ
OIA-oriented processing. It is **not** part of Alaveteli core and is not
normative for other jurisdictions.

| Alaveteli source state | Example external process state | Notes |
| --- | --- | --- |
| `waiting_response` | `RECEIVED` | Clock typically active after receipt. |
| `waiting_clarification` | `AWAITING_CLARIFICATION` | Clock may pause / restart under local law. |
| `gone_postal` | `SEARCHING` | Low confidence; offline handling. |
| `internal_review` | `INTERNAL_REVIEW_REQUESTED` | Review stage. |
| `successful` | `RELEASED_IN_FULL` | Platform success ≠ certified legal outcome. |
| `partially_successful` | `RELEASED_IN_PART` | Partial release. |
| `rejected` | `REFUSED` | Grounds remain in correspondence. |
| `not_held` | `NO_DOCUMENTS_FOUND` | Information not held. |
| `user_withdrawn` | `WITHDRAWN` | Clock stops. |
| `error_message` / `requires_admin` | `UNKNOWN` | Platform states. |
| `not_foi` | `CLOSED` | Non-FOI close. |

## Code pointers

| Concern | Location |
| --- | --- |
| Valid described states | `app/models/info_request/state.rb` |
| State roles (process / platform / admin / calculated) | `InfoRequest::State.roles` |
| Transitions & labels | `app/models/info_request/state/calculator.rb`, `transitions.rb` |
| Calculate display status | `InfoRequest#calculate_status` |
| Set described state | `InfoRequest#set_described_state` |
| Optional clock metadata | `InfoRequest#process_clock_metadata` |
| Theme custom states (example) | `spec/models/customstates.rb` |
| Authority API status field | `app/controllers/api_controller.rb` (`status`) |
| JSON representation | `InfoRequest#json_for_api` |
