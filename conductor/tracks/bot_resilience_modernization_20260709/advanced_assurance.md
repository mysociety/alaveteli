# Bot Traffic Resilience Modernization - Advanced Assurance & Testing

This document records the configurations, signatures, test designs, and results for RBS/Steep types, Property-Based Testing (PBT), mutation analysis, and Cuprite E2E coverage.

## 1. RBS & Steep Typing Configuration
We configure RBS and Steep to type-check our boundary models and controllers.

### 1.1 RBS Signatures (`sig/turnstile_validator.rbs`)
```rbs
class TurnstileValidator
  def self.validate: (String token, ?String? ip) -> bool
end
```

### 1.2 Steepfile Configuration
```ruby
target :app do
  signature "sig"
  check "app/services"
  check "app/contracts"
end
```

## 2. Property-Based Testing Design
PBT targets rate-limiting headers and retry delay invariants to ensure edge cases are handled correctly.

```ruby
# Example Property-Based Test design using Rantly
require 'rantly/rspec'

RSpec.describe "Rate Limit Header Math" do
  it "always calculates reset time inside period" do
    property_of {
      [range(1, 3600), range(0, 1000000)]
    }.check { |period, epoch_time|
      reset_in_seconds = period - (epoch_time % period)
      expect(reset_in_seconds).to be > 0
      expect(reset_in_seconds).to be <= period
    }
  end
end
```

## 3. Capybara Cuprite E2E Setup
We adopt Cuprite for headless Chrome testing without Selenium overhead.

```ruby
# spec/support/capybara_cuprite.rb
require 'capybara/cuprite'

Capybara.register_driver :cuprite do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1200, 800],
    browser_options: { 'no-sandbox': nil },
    headless: true
  )
end

Capybara.javascript_driver = :cuprite
```

## 4. Syntax Tree & Herb Linter Checks
*   **Syntax Tree:** Run `stree check` on selected files.
*   **Herb Linter:** Configured in check-only mode on `app/views/` templates to flag unescaped HTML injection.
