require 'English'
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'alaveteli_features/version'

Gem::Specification.new do |spec|
  spec.name          = "alaveteli_features"
  spec.version       = AlaveteliFeatures::VERSION
  spec.authors       = ["mySociety"]
  spec.email         = ["alaveteli@mysociety.org"]
  spec.description   = "Feature flags for Alaveteli"
  spec.summary       = "Helper methods to manage and test Alaveteli features"
  spec.homepage      = "https://alaveteli.org"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 8.0.1", "< 8.1.0"
  spec.add_dependency "flipper", "~> 1.3.2"
  spec.add_dependency "flipper-active_record", "~> 1.3.2"
  # Mime types 3 needs Ruby 2.0.0 or greater, but we need to support 1.9.3 so
  # force a lower version
  spec.add_dependency "mime-types", "< 4.0.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 13.1"
  spec.add_development_dependency "rspec", "~> 3.7"
  spec.add_development_dependency "rspec-rails", "~> 8.0"
end
