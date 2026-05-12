# the smallest "thing" we can search for (in info requests,
# incoming/outgoing messages, attachments, public bodies,
# comments...)
# Can be a paragraph, a page, a sheet in a spreadsheet, or
# an entire file depending on how each class defines its
# search capabilities
#
# The search_documents table is partitioned in postgresql for
# better search performance. This is why `id` is called `sd_id`,
# because Rails makes assumptions about the primary key that do
# not work with this setup.
#
# == Schema Information
#
# Table name: search_documents
#
#  sd_id               :bigint           not null, primary key
#  searchable_doc_type :string           not null, primary key
#  searchable_doc_id   :bigint
#  raw_content         :text
#  raw_admin_content   :text
#  section_ref         :text
#  language            :text
#  content_tsv         :tsvector
#  admin_content_tsv   :tsvector
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
class SearchDocument < ApplicationRecord
  belongs_to :searchable_doc, polymorphic: true
  self.primary_key = [:sd_id, :searchable_doc_type]

  # build the sql query for the search. This should be injection-safe.
  def self.hybrid_search_internal(
    query,
    model:,
    language:,
    limit:,
    admin_mode:,
    exact_mode:,
    semantic_threshold:,
    limit_ratio:
  )
    sanitized_language = if language.nil? || language == ''
                           Searchable.lang_from_locale(AlaveteliLocalization.default_locale)
                         else
                           language
                         end
    # remove some characters that postgresql is allergic to. These should never
    # reach this far though.
    sanitized_query = query.scrub("").delete("\u0000")
    query_values = { query: sanitized_query, language: sanitized_language }

    if model.nil?
      doc_type_q = ""
    else
      doc_type_q = "AND searchable_doc_type = '#{model}'"
    end

    # TODO: loading the model is slow (10+s) and memory hungry (10+GB),
    # so it needs to be locked away behind some kind of config flag.
    q_embedding = nil
    # q_embedding = @@model.call(query)

    # conditionnally build a query for each search type (exact, FTS, semantic)
    # and UNION them
    search_queries = []
    unless q_embedding.nil?
      #   semantic_query = "(1=1)"
      # else
      # semantic_query = <<-SQL
      search_queries << <<-SQL
        SELECT
            sd_id,
            rank() OVER (ORDER BY '#{q_embedding}'::vector <=> embedding) AS rank
        FROM search_documents
        WHERE embedding IS NOT NULL
            #{doc_type_q}
            AND ('#{q_embedding}'::vector <=> embedding) < #{semantic_threshold}
        ORDER BY '#{q_embedding}'::vector <=> embedding
        LIMIT #{limit * limit_ratio}
        SQL
    end

    if admin_mode
      # keep the same language for tokenization in admin mode, if the (admin) user wants
      # exact text match, they should use `exact_mode`.
      search_queries << <<~SQL.chomp
          SELECT
              sd_id,
              rank() OVER (
                ORDER BY ts_rank_cd(admin_content_tsv, plainto_tsquery(:language, unaccent(:query))) DESC
              ) AS rank
          FROM search_documents
          WHERE
              plainto_tsquery(:language, unaccent(:query)) @@ admin_content_tsv
              #{doc_type_q}
          ORDER BY rank
          LIMIT #{limit * limit_ratio}
        SQL
    end

    if admin_mode
      search_queries << <<-SQL
          SELECT
              sd_id,
              raw_content,
              rank() OVER (
                ORDER BY ts_rank_cd(admin_content_tsv, plainto_tsquery(#{query})) DESC
              ) AS rank
          FROM search_documents
          WHERE
              plainto_tsquery('simple', #{query}) @@ admin_content_tsv
              AND #{doc_type_q}
          ORDER BY rank
          LIMIT #{limit * 3}
        SQL
    end

    # exact_mode search is potentially costly as it is not backed by an index.
    # This should probably not be exposed to non-admins.
    if exact_mode
      if admin_mode
        adm_q = "OR raw_admin_content LIKE concat('%', :query::text, '%')"
      else
        adm_q = ""
      end
      search_queries << <<~SQL.chomp
        SELECT
          sd_id,
          rank() OVER (ORDER BY sd_id DESC) AS rank
        FROM search_documents
        WHERE
          raw_content LIKE concat('%', :query::text, '%')
          #{adm_q}
        LIMIT #{limit * limit_ratio}
      SQL
    end

    # all searches use the FTS ts_vectors
    search_queries << <<~SQL.chomp
        SELECT
            sd_id,
            rank() OVER (
              ORDER BY ts_rank_cd(content_tsv, plainto_tsquery(:language, unaccent(:query))) DESC
            ) AS rank
        FROM search_documents
        WHERE
            plainto_tsquery(:language, unaccent(:query)) @@ content_tsv
            AND language = :language
            #{doc_type_q}
        ORDER BY rank
        LIMIT #{limit * limit_ratio}
      SQL

    sql = <<~SQL.chomp.squeeze(' ')
      SELECT
        searches.sd_id,
        sum(searches.rank) AS rank_sum,
        sum(rrf_score(searches.rank)) AS score
      FROM ((#{search_queries.join(") UNION ALL (")})) searches
      GROUP BY searches.sd_id
      ORDER BY score DESC
      LIMIT #{limit}
    SQL

    { query: sql, values: query_values }
  end

  def self.hybrid_search(query,
                         model: nil,
                         language: nil,
                         limit: 10,
                         admin_mode: false,
                         exact_mode: false,
                         semantic_threshold: 0.6,
                         limit_ratio: 3)
    # try to provide some guidance during development
    unless Rails.env == 'production'
      if model.is_a? String
        raise(
          ArgumentError,
          "model should be a class, not its string representation"
        )
      end
      supported_langs = Searchable.class_variable_get(:@@locale_to_language_map).values.concat(
        [
          "simple",
          nil
        ]
      )
      unless supported_langs.include?(language)
        raise(ArgumentError, "#{language} is not yet supported for search")
      end
    end

    return SearchDocument.none if limit < 1

    sql = hybrid_search_internal(
      query,
      model: model,
      language: language,
      limit: limit,
      admin_mode: admin_mode,
      exact_mode: exact_mode,
      semantic_threshold: semantic_threshold,
      limit_ratio: limit_ratio
    )

    if model.nil?
      SearchDocument.where("sd_id IN (SELECT s.sd_id FROM (#{sql[:query]}) s)",
sql[:values])
    else
      sr = Arel.sql(sql[:query], **sql[:values])
      model.with(search_results: sr).joins(:search_documents).joins(
        "JOIN search_results " \
        "ON search_results.sd_id = search_documents.sd_id"
      )
    end
  end

  # temp code to remove before merging
  # TODO: do the same thing for the indexing part
  def self.fuzz_search
    models = [nil, PublicBody, Note, MailServerLog, FoiAttachment]
    languages = ['simple', nil, 'french', 'english']
    limits = [0, -1, 30]
    admin_modes = [true, false, nil]
    exact_modes = [true, false, nil]
    semantic_thresholds = [0.6]
    limit_ratios = [1, 3, 0]

    # one query string per line. https://gitlab.com/akihe/radamsa
    # provides an easy way to generate nasty test strings
    queries = IO.readlines('search_unique.txt')

    models.each do |model|
      languages.each do |language|
        limits.each do |limit|
          admin_modes.each do |admin_mode|
            exact_modes.each do |exact_mode|
              queries.each do |query|
                puts SearchDocument.hybrid_search(query,
                  model: model,
                  language: language,
                  limit: limit,
                  admin_mode: admin_mode,
                  exact_mode: exact_mode,
                  semantic_threshold: semantic_thresholds[0],
                  limit_ratio: limit_ratios[1]).count
              end
            end
          end
        end
      end
    end
  end
end
