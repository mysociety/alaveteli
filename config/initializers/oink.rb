# This can be added to either:
# config/environments/test.rb
# config/initializers/oink.rb
Rails.application.middleware.use Oink::Middleware if ENV['ALAVETELI_USE_OINK']
