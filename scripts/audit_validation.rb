# frozen_string_literal: true

puts "Running Bot Resilience Audit Validation Script..."

# Check Ruby Version
ruby_version_example = File.read('.ruby-version.example').strip rescue nil
puts "Ruby Version (Example): #{ruby_version_example}"

# Check Rails Version
gemfile = File.read('Gemfile')
rails_match = gemfile.match(/gem 'rails',\s*'([^']+)'/)
rails_version = rails_match ? rails_match[1] : 'unknown'
puts "Rails Version: #{rails_version}"

# Check dependencies
has_rack_attack = gemfile.include?('rack-attack')
has_sidekiq = gemfile.include?('sidekiq')
has_redis = gemfile.include?('redis')

puts "Rack::Attack present: #{has_rack_attack}"
puts "Sidekiq present: #{has_sidekiq}"
puts "Redis present: #{has_redis}"

# Check CI configurations
has_ci_workflow = File.exist?('.github/workflows/ci.yml')
has_rubocop_workflow = File.exist?('.github/workflows/rubocop.yml')
puts "CI Workflow present: #{has_ci_workflow}"
puts "RuboCop Workflow present: #{has_rubocop_workflow}"

puts "Audit Validation Complete!"
