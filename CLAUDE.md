# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Alaveteli is an open-source platform for making Freedom of Information (FOI) requests. It powers sites like WhatDoTheyKnow (UK) and similar FOI platforms worldwide. This is a Rails 8.0 application supporting Ruby 3.2-3.4.

**Important**: The main development branch is `develop`, not `master`. Pull requests should target `develop`.

## Development Commands

### Setup
```bash
bundle install
bin/rails db:migrate
bin/rails db:seed
```

### Running the Application
```bash
bin/rails server        # Starts Puma on port 3000
bin/rails console       # Rails console
```

### Testing
```bash
bundle exec rspec                              # Run full test suite
bundle exec rspec spec/path/to/file_spec.rb    # Run single file
bundle exec rspec spec/path/to/file_spec.rb:42 # Run specific test by line number
COVERAGE=local bundle exec rspec              # Run with coverage report
```

### Linting
```bash
bundle exec rubocop                    # Run RuboCop
bundle exec rubocop -a                 # Auto-fix issues
```

### Assets
```bash
bundle exec rake assets:precompile     # Compile assets for production
bundle exec rake assets:clean          # Clean compiled assets
bundle exec rake assets:link_non_digest # Link non-digest assets
```

### Xapian Search Index
```bash
bundle exec rake xapian:update_index                           # Update search index
bundle exec rake xapian:destroy_and_rebuild_index              # Rebuild from scratch
script/update-xapian-index verbose=true                        # Update with logging
```

### Themes
```bash
bundle exec rake themes:install        # Install configured theme
script/switch-theme.rb                # Switch between themes
```

### Background Jobs
Alaveteli uses Sidekiq for background job processing. Jobs are configured in `config/sidekiq.yml`.

### Useful Rake Tasks
```bash
bundle exec rake config_files:convert_crontab  # Generate crontab
bundle exec rake stats:update_public_bodies_stats
bundle exec rake users:sign_ins:purge
bundle exec rake public_body:export
```

## High-Level Architecture

### Core Models and Relationships

The FOI request system centers around these key models:

**InfoRequest** (`app/models/info_request.rb`)
- Represents a single FOI request
- States: `waiting_response`, `waiting_classification`, `successful`, `rejected`, `partially_successful`, etc.
- Has many `outgoing_messages` (request + follow-ups sent)
- Has many `incoming_messages` (responses received)
- Has many `info_request_events` (complete audit trail)
- Belongs to `user` (requester) and `public_body` (authority)

**User** (`app/models/user.rb`)
- Requester or admin account
- Uses `rolify` for role-based permissions
- Has many `info_requests`, `track_things` (subscriptions)

**PublicBody** (`app/models/public_body.rb`)
- Government authority/agency that receives FOI requests
- Each has a `request_email` where requests are sent
- Can have `censor_rules` for redacting sensitive information

**OutgoingMessage** (`app/models/outgoing_message.rb`)
- Messages sent TO public bodies
- Types: `initial_request`, `followup`
- Status: `ready`, `sent`, `failed`

**IncomingMessage** (`app/models/incoming_message.rb`)
- Responses received FROM public bodies
- Has many `foi_attachments` (file attachments)
- Belongs to `raw_email` (full MIME data preserved)

**InfoRequestEvent** (`app/models/info_request_event.rb`)
- Audit trail of everything that happens to a request
- Event types: `sent`, `response`, `status_update`, `comment`, `followup_sent`, `overdue`, etc.
- This is the primary model indexed by Xapian search

### FOI Request Flow

1. **User creates request** → `RequestController#new` → selects authority → writes request
2. **OutgoingMessage created** with status `ready`
3. **Email sent** to public body's request_email → OutgoingMessage status → `sent`
4. **InfoRequestEvent logged** (event_type: `sent`)
5. **Incoming email received** from public body (via POP3 polling or mail forwarding)
6. **MailHandler parses email** → extracts attachments → handles various formats (TNEF, PDF, Word, etc.)
7. **IncomingMessage created** with attachments
8. **InfoRequestEvent logged** (event_type: `response`)
9. **Request state updated** → `waiting_classification`
10. **User classifies response** (successful/rejected/etc.) → InfoRequestEvent logged

### Mail Handling System

**Incoming Mail** (`lib/mail_handler.rb`, `lib/alaveteli_mail_poller.rb`):
- Emails addressed to `request-[ID]-[HASH]@domain` where HASH = SHA1(ID + secret)[0:8]
- `AlaveteliMailPoller` retrieves from POP3 inbox (configured in `config/general.yml`)
- `MailHandler` parses MIME structure, extracts attachments, converts formats
- Supports TNEF (Outlook), PDF, Word, Excel, RTF → converts to text/HTML
- Error tracking in `IncomingMessageError` table

**Outgoing Mail**:
- `OutgoingMailer` - Sends requests/follow-ups to authorities
- `RequestMailer` - Sends alerts to users (new response, overdue, etc.)
- `TrackMailer` - Sends tracking notifications

### Xapian Search Engine

**Location**: `lib/acts_as_xapian/`

Xapian provides full-text search capabilities:
- Indexes: `InfoRequestEvent` (primary), `PublicBody`, `User`
- Supports faceted search by status, requester, authority, filetype, tags
- Range searches on dates
- Results can be collapsed by request (shows most relevant event per request)
- Config: `config/xapian.yml`
- Reindexing triggered automatically on model updates or manually via rake tasks

**Search Index Path**: `lib/acts_as_xapian/xapiandbs/`

### Background Jobs (Sidekiq)

**Location**: `app/jobs/`

Key jobs:
- `InfoRequestExpireJob` - Expires old requests (stops accepting responses)
- `FoiAttachmentMaskJob` - Applies redactions/censoring to attachments
- `NotifyCacheJob` - Cache invalidation after changes

Scheduled tasks (via cron - see `config/crontab-example`):
- Every 5 minutes: Update Xapian index
- Every 10 minutes: Send batch requests
- Hourly: Alert tasks
- Daily: Cleanup, expiration, statistics

### Theming System

**Location**: `lib/themes/`, `lib/theme.rb`

- Git-based: themes are full git repositories cloned into `lib/themes/`
- Can override: views, CSS, JavaScript, locales, configuration
- Installed via `rake themes:install`
- Example themes in production: `alavetelitheme` (base), `accessinfohktheme` (Hong Kong)

### Request States and Prominence

**States** (in `described_state` field):
- **Awaiting response**: `waiting_response` → `overdue` (21 days) → `very_overdue` (60 days)
- **Awaiting classification**: `waiting_classification` (user needs to classify response)
- **Outcomes**: `successful`, `partially_successful`, `rejected`, `not_held`
- **Admin states**: `requires_admin`, `vexatious`, `not_foi`

**Prominence** (visibility control):
- `normal` - Publicly visible
- `hidden` - Only admins and requester can see
- `requester_only` - Only requester can see (used for embargoes)
- Applies to: InfoRequest, IncomingMessage, OutgoingMessage, FoiAttachment, Comment

### Key Configuration Files

- `config/general.yml` - Main application config (mail settings, domain, FOI law, etc.)
- `config/database.yml` - PostgreSQL connection
- `config/storage.yml` - ActiveStorage backends (S3, Google Cloud Storage)
- `config/sidekiq.yml` - Background job queues
- `lib/configuration.rb` - Configuration class that loads general.yml

## Important Development Notes

### Database
- Uses **PostgreSQL**
- Schema format: **SQL** (not Ruby schema.rb) - see `config/application.rb:71`
- Run migrations: `bin/rails db:migrate`

### Testing
- **RSpec** test suite with **FactoryBot** for fixtures
- Coverage: SimpleCov (activated with `COVERAGE=local` or in CI)
- Fixtures: `spec/fixtures/`
- Global fixtures loaded in order: users, roles, users_roles, public_bodies, etc.

### Gem Versioning Policy
See `Gemfile` header for detailed policy:
- Most gems locked at PATCH level: `gem 'foo', '~> 1.2.0'`
- Some gems from GitHub forks (e.g., acts_as_versioned, ruby-msg)
- Upgrade with `bundle update gem_name`

### Internationalization
- Uses `gettext` + `globalize` for translations
- Locale files: `locale/` and `locale_alaveteli_pro/`
- Supported locales: Many (50+ languages)
- Translation management via Transifex

### Key Directories
- `app/` - Standard Rails structure (models, controllers, views, jobs, mailers)
- `lib/` - Custom libraries (mail_handler, acts_as_xapian, configuration, etc.)
- `spec/` - RSpec tests
- `script/` - Maintenance/cron scripts
- `config/` - Configuration files
- `db/` - Database migrations and seeds
- `commonlib/` - Shared mySociety utilities (git submodule)

### Running Single Script Files
Many maintenance operations are in `script/` directory:
```bash
script/update-xapian-index
script/send-batch-requests
script/alert-overdue-requests
```

These wrap rake tasks or Rails runner commands.

## Common Development Scenarios

### Adding a new FOI request field
1. Add migration for `info_requests` table
2. Update `InfoRequest` model with validation
3. Update `RequestController` to handle new field
4. Update views in `app/views/request/`
5. Update factories in `spec/factories/info_requests.rb`
6. Add specs in `spec/models/info_request_spec.rb`

### Modifying mail handling
1. Code is in `lib/mail_handler.rb`
2. Tests in `spec/lib/mail_handler_spec.rb`
3. Incoming messages parsed by `MailHandler.receive(email_data)`
4. Test fixtures in `spec/fixtures/files/` (sample emails)

### Changing search behavior
1. Search indexing: `lib/acts_as_xapian/`
2. Search controller: `app/controllers/search_controller.rb`
3. Reindex after changes: `rake xapian:destroy_and_rebuild_index`
4. Model search config in model files (e.g., `InfoRequestEvent.acts_as_xapian`)

### Adding a new background job
1. Create in `app/jobs/` inheriting from `ApplicationJob`
2. Enqueue with `YourJob.perform_later(args)`
3. Add queue to `config/sidekiq.yml` if needed
4. Test in `spec/jobs/`

### Working with themes
1. Themes override default views/assets
2. Check `lib/themes/[theme_name]/` for theme-specific code
3. Fall back to default if theme doesn't override
4. Install/update: `rake themes:install`
