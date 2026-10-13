# Selects the live search query backend from configuration, defaulting to
# Xapian. Runs after initialization so the Search facade (required in the
# zeitwerk initializer) and the adapter classes are loaded. See doc/SEARCH.md
# for the backend-authoring contract.
Rails.application.config.after_initialize do
  Search.use_configured_backend!
end
