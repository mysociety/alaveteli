$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "alaveteli_pro/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "alaveteli_pro"
  s.version     = AlaveteliPro::VERSION
  s.authors     = ["mySociety"]
  s.email       = ["alaveteli-pro@mysociety.org"]
  s.homepage    = "http://www.alaveteli.org"
  s.summary     = "An add-on for Alaveteli sites to provide features for " \
                  "journalists and other professional FOI users."
  s.description = "An add-on for Alaveteli sites to provide features for " \
                  "journalists and other professional FOI users."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 3.2.22.3"

  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'factory_girl_rails'
  s.add_development_dependency 'shoulda-matchers'
  s.add_development_dependency 'jquery-rails' # The dummy app needs it
  s.add_development_dependency 'pg' # The dummy app needs it
end
