# Implementation Plan - User Notification Preferences Dashboard

## Phase 1: Database and Model Layer [checkpoint: 7357f07]

- [x] Task: Database Migration for Notification Preferences [5a16d4b]
    - [x] Write model and migration tests to verify new attributes and defaults
    - [x] Create and run migration adding `send_daily_summary` and `send_immediate_request_alerts` to users table
    - [x] Implement attribute defaults and validations in `User` model
- [x] Task: Conductor - User Manual Verification 'Phase 1: Database and Model Layer' (Protocol in workflow.md) [7357f07]

## Phase 2: Routing and Controller [checkpoint: 20b24b8]

- [x] Task: Settings Controller and Actions [40d4fe1]
    - [x] Write controller tests verifying update authorization and strong parameter parsing
    - [x] Create or extend controller actions to update notification preferences
    - [x] Configure routes for the preferences update endpoint
- [x] Task: Conductor - User Manual Verification 'Phase 2: Routing and Controller' (Protocol in workflow.md) [20b24b8]

## Phase 3: User Interface [checkpoint: fd0365a]

- [x] Task: Settings Dashboard View [e67ed1c]
    - [x] Write integration and view tests for the notification settings interface
    - [x] Implement settings form in ERB template with toggles for notification flags
    - [x] Add basic styling and responsive layout for mobile compatibility
- [x] Task: Conductor - User Manual Verification 'Phase 3: User Interface' (Protocol in workflow.md) [fd0365a]

## Phase 4: Integration and Mailers [checkpoint: e185cb2]

- [x] Task: Integrate Preferences with Mailers and Jobs [76cea72]
    - [x] Write mailer and job tests verifying email suppression based on preferences
    - [x] Update notification jobs and mailers to honor preference flags
- [x] Task: Conductor - User Manual Verification 'Phase 4: Integration and Mailers' (Protocol in workflow.md) [e185cb2]
