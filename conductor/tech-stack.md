# Technology Stack - Alaveteli

## Core Stack
*   **Language:** Ruby 3.4.x
*   **Backend Framework:** Ruby on Rails 8.0.x (MVC monolithic framework)
*   **Database:** PostgreSQL (with `pg` adapter)

## Auxiliary Services
*   **Search Engine:** Xapian (integrated via the `xapian-full-alaveteli` gem)
*   **Background Jobs:** Sidekiq (for asynchronous tasks such as sending emails, loading logs, and updating search indexes)
*   **Key-Value Stores:**
    *   Redis (for Sidekiq job queuing and caching)
    *   Memcached (accessed via `dalli` for general cache)

## Frontend & Assets
*   **Asset Management:** Sprockets (Sass) and Rails Importmaps
*   **Frontend Frameworks:** Hotwire (Turbo & Stimulus)
*   **Standard CSS:** Custom Sass with Bootstrap-Sass (v2.3) and Foundation SCSS utilities

## Testing & Quality Assurance
*   **Test Runner:** RSpec (`rspec-rails`)
*   **Browser/Integration Testing:** Capybara
*   **Mocking/Stubbing:** WebMock
*   **Code Coverage:** SimpleCov
*   **Linting:** RuboCop (including `rubocop-performance` and `rubocop-rails`)
