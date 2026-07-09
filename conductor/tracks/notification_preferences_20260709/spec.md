# Track Specification - User Notification Preferences Dashboard

## 1. Goal
Provide users with a dedicated settings dashboard to manage their email notification preferences. This helps reduce email volume and improves the overall user experience.

## 2. Requirements

### 2.1 Database & Model
*   Add preference attributes to the `User` model:
    *   `send_daily_summary` (boolean, default: true)
    *   `send_immediate_request_alerts` (boolean, default: true)
*   Add database migrations to back these new columns.
*   Update validations and default settings on the model.

### 2.2 Controller & Routing
*   Create a settings controller (or update the existing account/user profile controller) to handle setting modifications.
*   Secure the update endpoint so only the authenticated user can change their own settings.
*   Verify strong parameters and routing.

### 2.3 Frontend Interface
*   Add a "Notification Preferences" tab or section to the user settings/profile page.
*   Create toggle switches or checkboxes corresponding to the preference flags.
*   Provide clear success and error messages on submission.

### 2.4 Mailer & Job Integration
*   Update relevant mailers and background jobs (e.g. `NotificationMailer`) to check the user's notification preferences before sending alerts or digests.
*   If a preference is disabled (e.g. `send_daily_summary` is false), the corresponding email delivery should be skipped.
