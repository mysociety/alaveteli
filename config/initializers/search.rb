# Selects the live search query backend from configuration, defaulting to
# Xapian. Runs on every code reload too, as a reload replaces the Search
# facade and with it the backend set at boot. See doc/SEARCH.md for the
# backend-authoring contract.
Rails.application.config.to_prepare do
  Search.use_configured_backend!
end
