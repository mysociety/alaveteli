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
    "fr_BE" => 'french',
    "fr_FR" => 'french',
    "hu" => 'hungarian',
    "nl" => 'dutch',
    "sv_SE" => 'swedish'
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

  # instance methods that help build SQL queries for indexing
  # searchable models.
  #
  # The aim is to have updates run as much as possible inside the db
  # to speed up (re)indexing.
  # TODO: do we need an "admin_search_content" that includes various bits that
  # we do NOT want regular users to search through? (user email addresses,
  # edit comments, ...). These would most likely be searched only for GDPR purposes,
  # so can
  def search_raw_content_query
    # TODO: adjust this to match the method below for content_tsv
    opts = @@searchable_models[self.class.to_s]
    query = <<-SQL
      SELECT concat(#{opts[:index].keys.join(',')})
      FROM #{self.class.table_name}
      WHERE id=$1
    SQL
    query
  end

  # We can't just use the raw_content here, because it has lost the
  # weight from various columns.
  def search_content_tsv_query(idx_name, language)
    opts = @@searchable_models[self.class.to_s]

    content_tsv_bits = []
    opts[idx_name].each do |col, w|
      if col.start_with?(".")
        c = ActiveRecord::Base.connection.quote(send(col[1..])).to_s
      else
        c = col
      end

      content_tsv_bits.push(
        "setweight(to_tsvector('#{language}'::regconfig, coalesce(#{c}, '')), '#{w}')"
      )
    end

    query = <<-SQL
      SELECT #{content_tsv_bits.join("||")} AS tsv
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
  def search_content_tsv(idx_name, language)
    ActiveRecord::Base.
      connection.
      exec_query(
        search_content_tsv_query(idx_name, language),
        "Search content_tsv",
        [ActiveRecord::Relation::QueryAttribute.new("somename", id, ActiveRecord::Type::Integer.new)]
      )
  end

  # upsert the content_tsv column.
  # This may result in multiple search docs:
  # if model is translatable
  # if model has multiple pages/paragraphs...
  def upsert_content_tsv(language, section_ref)
    search_cfg = @@searchable_models[self.class.to_s]
    puts("search_cfg = #{search_cfg}")
    record = {
      searchable_doc_type: self.class.to_s,
      searchable_doc_id: id,
      # TODO: merge the 2 queries below into a single one
      admin_content_tsv: search_content_tsv(:admin_index,
'simple').to_a.first["tsv"]
      language: language,
      section_ref: section_ref,
      content_tsv: if search_cfg[:index].empty?
                     nil
                   else
                     search_content_tsv(
                       :index,
                       language
                     ).
                       to_a.
                       first["tsv"]
                   end,
    }
    SearchDocument.upsert(
      record,
      unique_by: [:searchable_doc_type, :searchable_doc_id, :section_ref,
                  :language],
      update_only: [:content_tsv]
    )
  end

  # Refresh the search index data about a model.
  # This would be the right place to queue up jobs like content extraction,
  # embedding generation, etc...
  def reindex
    if respond_to?(:translated_versions)
      translations_by_locale.each do |l, v|
        AlaveteliLocalization.with_locale(l) do
          upsert_content_tsv(Searchable.lang_from_locale(l.to_s), 1)
        end
      end
    else
      # TODO: what language to use here?
      upsert_content_tsv(
        Searchable.lang_from_locale(AlaveteliConfiguration.default_locale), 1
      )
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
    # +admin_mode+ adjusts the search for admin users (controllers still control permissions)
    # +limit+ how many records to return.
    def newsearch(query,
                  language: Searchable.lang_from_locale(AlaveteliConfiguration.default_locale),
                  admin_mode: false,
                  limit: 10)
      unless Searchable.class_variable_get(:@@searchable_models).include?(name)
        raise(
          NotImplementedError,
          "Call #{self}.searchable to make the model searchable"
        )
      end
      puts(self)

      SearchDocument.hybrid_search(
        query,
        model: self,
        language: language,
        admin_mode: admin_mode,
        limit: limit
      )
    end

    # Reindex all instances of a model.
    # This would normally not be run beyond the initial indexing of a
    # pre-existing database.
    def reindex_all(batch_size: 1000)
      start = Time.now
      find_each(batch_size: batch_size) do |m|
        m.reindex
      end
      t = Time.now - start
      Rails.logger.info("Reindexed #{all.count} #{name} in #{t} seconds")
    end
  end

  def self.included(base)
    base.extend(SearchableMethods)
  end
end

ActiveRecord::Base.extend(Searchable::SearchableMethods)
