PgSearch.multisearch_options = {
  using: { tsearch: { dictionary: "french", prefix: true }, trigram: {} },
  ignoring: :accents
}
