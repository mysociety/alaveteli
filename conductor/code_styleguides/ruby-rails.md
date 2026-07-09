# Ruby on Rails Code Style Guide

This style guide defines the coding standards, patterns, and safety requirements for our Ruby on Rails application.

## 1. General Ruby Principles
*   **Follow the Community Style Guide:** Adhere to the [Ruby Style Guide](https://github.com/rubocop/ruby-style-guide). Use `rubocop` to automate style verification.
*   **Keep Methods Short:** Avoid methods longer than 10 lines. Extract logic to helper methods, service objects, or query objects.
*   **Avoid Global Variables:** Do not use global variables (e.g., `$global`). Use configuration settings, constants, or context parameters instead.

## 2. Rails Controller Guidelines
*   **Keep Controllers Thin:** Controllers should only handle HTTP routing, request parsing, authentication/authorization checks, and rendering/redirection. Business logic belongs in models or service objects.
*   **Strong Parameters:** Always sanitize parameters using `params.require(...).permit(...)`. Never permit raw params.
*   **RESTful Routing:** Prefer standard RESTful routes (`index`, `show`, `new`, `create`, `edit`, `update`, `destroy`). Avoid custom member/collection routes unless absolutely necessary.

## 3. Rails Model Guidelines
*   **Fat Models, Thin Controllers:** Business logic and data validations belong in models or dedicated service objects.
*   **Validations:** Always validate data integrity. Specify `presence`, `uniqueness`, and format validations where appropriate.
*   **Database Constraints:** Accompany model validations with database constraints (e.g., `NOT NULL`, foreign keys, unique indexes) to prevent race conditions.
*   **Callbacks:** Minimize the use of ActiveRecord callbacks (`before_save`, `after_commit`). They can cause unexpected side effects and make testing difficult.

## 4. Quality & Linting Settings
*   **RuboCop:** Run `bundle exec rubocop` before every commit. Zero offenses are allowed.
*   **Brakeman:** Run `bundle exec brakeman` to perform static security analysis. Zero warnings/errors are tolerated.
*   **Test Coverage:** All new code must be accompanied by comprehensive tests (RSpec) achieving at least **90% coverage**.

## 5. Security & Protection Guidelines
*   **SQL Injection Prevention:** Never interpolate user input directly into SQL strings. Always use parameterized queries, e.g., `User.where("name = ?", params[:name])` or `User.where(name: params[:name])`.
*   **Cross-Site Scripting (XSS) Prevention:**
    *   Rails automatically escapes output in ERB templates.
    *   Avoid using `raw` or `.html_safe` on user-supplied input unless it has been explicitly sanitized using `sanitize` or a vetted library.
*   **Mass Assignment Prevention:** Always use Strong Parameters. Never call `User.new(params)` or similar directly.
*   **CSRF Protection:** Ensure `protect_from_forgery with: :exception` (or `:null_session` for APIs) is present in `ApplicationController`.
*   **API Security:** All API endpoints must enforce strict token validation, rate-limiting, and HTTPS/SSL.
