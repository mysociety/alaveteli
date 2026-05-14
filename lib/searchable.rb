# Define search methods common to all searchable models
module Searchable
  # rubocop:disable Style/ClassVars
  # store rails models that are searchable, with settings for each of them.
  # See the `searchable` method below for details.
  @@searchable_models = {}

  # map alaveteli locales to a corresponding language search config
  # see https://www.postgresql.org/docs/current/textsearch-dictionaries.html
  # This is limited to the languages currently in use on Alaveteli.
  @@locale_to_language_map = {
    "el" => 'greek',
    "en" => 'english',
    "es" => 'spanish',
    "fr" => 'french',
    "fr_BE" => 'french',
    "fr_FR" => 'french',
    "hu" => 'hungarian',
    "nl" => 'dutch',
    "sv_SE" => 'swedish',
    "sv" => 'swedish'
  }
  # fallback on "simple" which does not try to stem words at all. This allows
  # search to work in any language, but without tokenisation/stemming.
  @@locale_to_language_map.default = 'simple'
  # rubocop:enable Style/ClassVars

  def self.lang_from_locale(locale)
    @@locale_to_language_map[locale]
  end

  # TODO: rename to `search`
  # Search entry point for searching a single instance of a model.
  def newsearch(_query)
    Rails.logger.info("Searching through instance #{self.class}.#{id}")
  end

  # We can't just use the raw_content here, because it has lost the
  # weight from various columns.
  def search_content_from_db_query(idx_name, language)
    opts = @@searchable_models[self.class.to_s]

    raw_content_bits = []
    content_tsv_bits = []
    opts[idx_name].each do |col, w|
      if col.start_with?(".")
        c = ActiveRecord::Base.connection.quote("#{send(col[1..])} ")
      else
        c = "(SELECT concat(#{col}, ' ') FROM #{self.class.table_name} WHERE id=$1)"
      end

      raw_content_bits.push(c)
      content_tsv_bits.push(
        "setweight(to_tsvector('#{language}'::regconfig, unaccent(coalesce(#{c}, ''))), '#{w}')"
      )
    end

    query = <<-SQL
      SELECT
        concat(#{raw_content_bits.join(',')}) as raw,
        #{content_tsv_bits.join("||")} AS tsv
      FROM #{self.class.table_name}
      WHERE id=$1
    SQL
    query
  end

  # Build a tsvector record for the model+language combination.
  #
  # +idx_name+ is either :index of :admin_index
  # +language+ is the language for the pg dictionary to tokenize content.
  #            For :admin_index, language is always 'simple'
  # TODO: if all keys in :idx_name are column names, we don't need to send the
  # query to the db, we can just pass it back to the upsert call to save one
  # round trip to db.
  def search_content_from_db(idx_name, language)
    search_cfg = @@searchable_models[self.class.to_s]
    if search_cfg[idx_name].nil? or search_cfg[idx_name].empty?
      {}
    else
      ActiveRecord::Base.
        connection.
        exec_query(
          search_content_from_db_query(idx_name, language),
          "Search content query",
          [ActiveRecord::Relation::QueryAttribute.new(
            "somename",
            id,
            ActiveRecord::Type::Integer.new
          )]
        ).to_a.first
    end
  end

  # upsert the content_tsv column.
  # This may result in multiple search docs:
  # if model is translatable
  # if model has multiple pages/paragraphs...
  def upsert_content(language, section_ref)
    search_cfg = @@searchable_models[self.class.to_s]

    content_from_db = search_content_from_db(
      :index,
      language
    )
    admin_content_from_db = search_content_from_db(
      :admin_index,
      language
    )

    record = {
      searchable_doc_type: self.class.to_s,
      searchable_doc_id: id,
      language: language,
      section_ref: section_ref,
      raw_content: content_from_db["raw"],
      raw_admin_content: admin_content_from_db["raw"],
      content_tsv: content_from_db["tsv"],
      admin_content_tsv: admin_content_from_db["tsv"]
    }
    SearchDocument.upsert(
      record,
      unique_by: [:searchable_doc_type,
                  :searchable_doc_id,
                  :section_ref,
                  :language],
      update_only: [:raw_content,
                    :raw_admin_content,
                    :content_tsv,
                    :admin_content_tsv]
    )
  end

  # Override this method per model to allow excluding specific objects
  # from indexing.
  def is_indexable
    true
  end

  # Refresh the search index data about a model.
  # This would be the right place to queue up jobs like content extraction,
  # embedding generation, etc...
  def reindex
    return unless is_indexable

    if respond_to?(:translated_versions)
      translations_by_locale.each do |l, v|
        AlaveteliLocalization.with_locale(l) do
          lang = Searchable.lang_from_locale(l.to_s)
          # TODO: 1 is the section/page/etc... which needs to be
          # extracted from content where relevant
          upsert_content(lang, 1)
        end
      end
    else
      lang = Searchable.lang_from_locale(AlaveteliLocalization.default_locale)
      upsert_content(lang, 1)
    end
  end

  # Class methods that are added on all models. To make a model searchable,
  # call `MyModel.searchable(options)` on it.
  # Search is then available through `MyModel.newsearch("search query")`.
  module SearchableMethods
    # make a model searchable by calling this in its definition.
    # searchable takes a hash like:
    # {
    #   index: {
    #     # define all columns (or methods) to include in the search index
    #     # with the respective weight (as used by postgres)
    #     # Prefix ruby method names with a ".", otherwise the column name
    #     # will be passed to postgres unmodified.
    #     # Reindexing columns is faster, as the data does not need to travel
    #     # from pg to ruby and back.
    #     # The value for each key (A, B, C, D) is the relative weight
    #     # attached to the text in that col/method (A being highest).
    #     "column_name": <A|B|C|D>
    #     ".method_name": <A|B|C|D>
    #     ...
    #     },
    #   admin_index: {
    #     # :admin_index uses the same syntax as :index, but given its GDPR
    #     # focus, the weight is less important here, all columns can be
    #     # marked the same.
    #     "column_name": <A|B|C|D>,
    #     ".method_name": <A|B|C|D>,
    #   },
    #   # Fields the search results can be filtered by,
    #   # to limit search perimeter or do facetting.
    #   filterable: [:col_a, :col_b],
    #   # which fields the search results can be sorted by
    #   sortable: [:col_c, :col_d]
    # end
    def searchable(options)
      Searchable.class_variable_get(:@@searchable_models)[name] = options
    end

    # TODO: rename this to `search`
    # The main entry point to the search API. All search calls should go through
    # this method.
    #
    # +query+ is the plain text searched for
    # +model+ pass a rails model (PublicBody, InfoRequest...) to limit search
    #         scope to instances of it
    # +language+ is the language in which the search is done.
    # +admin_mode+ adjusts the search for admin users (controllers still control
    #              permissions), to include items that match the search query
    #              based on the content of their `admin_index` elements.
    # +exact_mode+ adds results that match *exactly* the query text, using
    #              SQL LIKE search. This combines with `admin_mode` to also search
    #              in the raw_admin_content. This search mode is potentially
    #              slow/expensive on models with many instances.
    # +limit+ how many records to return.
    def newsearch(query,
                  language: Searchable.lang_from_locale(AlaveteliLocalization.default_locale),
                  admin_mode: false,
                  exact_mode: false,
                  limit: 10)
      unless Searchable.class_variable_get(:@@searchable_models).include?(name)
        raise(
          NotImplementedError,
          "Call #{self}.searchable to make the model searchable"
        )
      end

      SearchDocument.hybrid_search(
        query,
        model: self,
        language: language,
        admin_mode: admin_mode,
        exact_mode: exact_mode,
        limit: limit
      )
    end

    # Reindex all instances of a model.
    # This would normally not be run beyond the initial indexing of a
    # pre-existing database.
    def reindex_all(batch_size: 1000)
      start = Time.now
      indexable.find_each(batch_size: batch_size) do |m|
        m.reindex
      end
      t = Time.now - start
      Rails.logger.info("Reindexed #{indexable.count} #{name} in #{t} seconds")
    end
  end

  def self.included(base)
    base.class_eval do
      has_many :search_documents, as: :searchable_doc
      # Override this scope to help filter out records which don't need
      # reindexing in `reindex_all`.
      scope :indexable, -> {}
    end
    base.extend(SearchableMethods)
  end
end

ActiveRecord::Base.extend(Searchable::SearchableMethods)
