# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'alaveteli_features/version'

Gem::Specification.new do |spec|
  spec.name          = "alaveteli_features"
  spec.version       = AlaveteliFeatures::VERSION
  spec.authors       = ["mySociety"]
  spec.email         = ["alaveteli@mysociety.org"]
  spec.description   = "Feature flags for Alaveteli"
  spec.summary       = "Feature flags for Alaveteli"
  spec.homepage      = "https://alaveteli.org"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", "~> 4.0.13"
  spec.add_dependency "flipper"
  spec.add_dependency "flipper-active_record"
  # Mime types 3 needs Ruby 2.0.0 or greater, but we need to support 1.9.3 so
  # force a lower version
  spec.add_dependency "mime-types", "< 3.0.0"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-rails"
end
