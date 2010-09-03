
production = (ENV['PRODUCTION'] == "true")

config.cache_classes = production
config.whiny_nils = true
config.action_controller.consider_all_requests_local = !production
config.action_controller.perform_caching = true
config.action_view.debug_rjs = !production
config.action_mailer.raise_delivery_errors = false
