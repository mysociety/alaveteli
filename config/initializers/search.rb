# Selects the live search query backend and the set of backends kept indexed
# from configuration, defaulting to Xapian. Runs after initialization so the
# Search facade (required in the zeitwerk initializer) and the adapter classes
# are loaded. See doc/SEARCH.md for the backend-authoring contract.
Rails.application.config.after_initialize do
  Search.use_configured_backends!
end
