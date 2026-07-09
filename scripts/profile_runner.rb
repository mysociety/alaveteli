# frozen_string_literal: true

require 'fileutils'
require 'json'

# Ensure we can load Vernier safely (optional fallback for non-development environments)
begin
  require 'vernier'
rescue LoadError
  puts "Vernier gem not installed or not available in this environment."
  exit 1
end

workload = ARGV[0] || 'all'
output_dir = 'tmp/profiles'
FileUtils.mkdir_p(output_dir)

def profile_block(name, output_dir)
  puts "Profiling #{name}..."
  result = Vernier.trace(profile: :custom) do
    # Simulating workload block
    case name
    when 'request_page'
      # Simulate request processing
      1000.times { "request-#{rand(100)}".split('-') }
    when 'search'
      # Simulate search operations
      1000.times { Regexp.new("bot").match?("anonymous-bot-scraper") }
    when 'rate_limit'
      # Simulate rate limit check
      1000.times { Time.now.to_i % 60 }
    when 'bulk_export'
      # Simulate bulk NDJSON export serialization
      100.times { { id: rand(100), title: "FOI Request", body: "Metadata text info" }.to_json }
    end
  end
  
  output_file = File.join(output_dir, "#{name}_profile.json")
  File.write(output_file, JSON.dump(result.to_h rescue {}))
  puts "Saved profile to #{output_file}"
end

if workload == 'all'
  %w[request_page search rate_limit bulk_export].each do |wl|
    profile_block(wl, output_dir)
  end
else
  profile_block(workload, output_dir)
end
