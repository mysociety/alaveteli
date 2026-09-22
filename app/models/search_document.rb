# == Schema Information
#
# Table name: search_documents
#
#  sd_id             :bigint           not null, primary key
#  searchable_type   :string           not null, primary key
#  searchable_id     :bigint
#  raw_content       :text
#  raw_admin_content :text
#  section_ref       :text
#  language          :text
#  content_tsv       :tsvector
#  admin_content_tsv :tsvector
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  root_type         :string
#  root_id           :bigint

##
# The smallest "thing" we can search for (in info requests, incoming/outgoing
# messages, attachments, public bodies, comments...) Can be a paragraph, a
# page, a sheet in a spreadsheet, or an entire file depending on how each class
# defines its search capabilities
#
# The search_documents table is partitioned in postgresql for better search
# performance. This is why `id` is called `sd_id`, because Rails makes
# assumptions about the primary key that do not work with this setup.
#
class SearchDocument < ApplicationRecord
  belongs_to :searchable, polymorphic: true
  belongs_to :root, polymorphic: true
  self.primary_key = [:searchable_type, :sd_id]

  scope :not_embargoed, NotEmbargoedQuery.new

  # build the sql query for the search. This should be injection-safe.
  def self.hybrid_search_internal(
    query,
    model:,
    language:,
    limit:,
    admin_mode:,
    exact_mode:,
    case_sensitive:,
    limit_ratio:
  )
    # coerce values that are interpolated into the SQL rather than bound,
    # so a non-numeric value raises instead of reaching the query.
    limit = Integer(limit)
    limit_ratio = Integer(limit_ratio)

    sanitized_language = if language.nil? || language == ''
                           Searchable.
                             lang_from_locale(
                               AlaveteliLocalization.default_locale
                             )
                         else
                           language
                         end
    # remove some characters that postgresql is allergic to. These should never
    # reach this far though.
    sanitized_query = query.scrub("").delete("\u0000")
    query_values = { query: sanitized_query, language: sanitized_language }

    if model.nil?
      doc_type_q = ""
    elsif model.is_a?(Array)
      doc_type_q = "AND searchable_type IN (:models)"
      query_values[:models] = model.map(&:to_s)
    else
      doc_type_q = "AND searchable_type = :model"
      query_values[:model] = model.to_s
    end

    # and UNION them
    search_queries = []

    if admin_mode
      # keep the same language for tokenization in admin mode, if the (admin)
      # user wants exact text match, they should use `exact_mode`.
      search_queries << <<~SQL.chomp
          SELECT
              sd_id,
              searchable_type,
              searchable_id,
              root_type,
              root_id,
              rank() OVER (
                ORDER BY ts_rank_cd(admin_content_tsv, websearch_to_tsquery(:language, unaccent(:query))) DESC
              ) AS rank
          FROM search_documents
          WHERE
              websearch_to_tsquery(:language, unaccent(:query)) @@ admin_content_tsv
              #{doc_type_q}
          ORDER BY rank
          LIMIT #{limit * limit_ratio}
        SQL
    end

    # exact_mode search is potentially costly as it is not backed by an index.
    # This should probably not be exposed to non-admins.
    if exact_mode
      # escape LIKE wildcards so the query text is matched literally
      query_values[:like_query] = "%#{sanitize_sql_like(sanitized_query)}%"
      like_op = case_sensitive ? "LIKE" : "ILIKE"
      if admin_mode
        adm_q = "OR raw_admin_content #{like_op} :like_query"
      else
        adm_q = ""
      end
      search_queries << <<~SQL.chomp
        SELECT
          sd_id,
          searchable_type,
          searchable_id,
          root_type,
          root_id,
          rank() OVER (ORDER BY sd_id DESC) AS rank
        FROM search_documents
        WHERE
          (raw_content #{like_op} :like_query
          #{adm_q})
          #{doc_type_q}
        LIMIT #{limit * limit_ratio}
      SQL
    end

    # all searches use the FTS ts_vectors
    search_queries << <<~SQL.chomp
        SELECT
            sd_id,
            searchable_type,
            searchable_id,
            root_type,
            root_id,
            rank() OVER (
              ORDER BY ts_rank_cd(content_tsv, websearch_to_tsquery(:language, unaccent(:query))) DESC
            ) AS rank
        FROM search_documents
        WHERE
            websearch_to_tsquery(:language, unaccent(:query)) @@ content_tsv
            AND language = :language
            #{doc_type_q}
        ORDER BY rank
        LIMIT #{limit * limit_ratio}
      SQL

    sql = <<~SQL.chomp.squeeze(' ')
      SELECT
        searches.sd_id,
        searches.searchable_type,
        searches.searchable_id,
        searches.root_type,
        searches.root_id,
        sum(searches.rank) AS rank_sum,
        sum(rrf_score(searches.rank)) AS score
      FROM ((#{search_queries.join(") UNION ALL (")})) searches
      GROUP BY searches.sd_id, searches.searchable_type, searches.searchable_id,
        searches.root_type, searches.root_id
      ORDER BY score DESC
      LIMIT #{limit}
    SQL

    { query: sql, values: query_values }
  end
  private_class_method :hybrid_search_internal

  # Run the hybrid full-text search and return a chainable relation.
  #
  # +relation+ an optional base ActiveRecord::Relation to search within;
  #            defaults to +model.all+. Lets callers pre-filter the search
  #            perimeter and chain further conditions onto the result.
  # +model+ the model class to search; inferred from +relation+ when omitted.
  #         When both are nil the search spans every model and returns a
  #         SearchDocument relation.
  # +case_sensitive+ only affects exact_mode's substring matching; when false
  #                  it matches regardless of case (ILIKE). Full-text matching
  #                  is always case-insensitive via tsvector normalisation.
  def self.hybrid_search(query,
                         relation: nil,
                         model: nil,
                         language: nil,
                         limit: 10,
                         admin_mode: false,
                         exact_mode: false,
                         case_sensitive: true,
                         limit_ratio: 3)
    # validate all inputs before any SQL is built from them. This must
    # run in every environment as it is part of keeping the query
    # injection-safe.
    if !model.nil? && !model.is_a?(Class)
      raise(
        ArgumentError,
        "model should be a class, not its string representation"
      )
    end

    relation ||= model&.all
    model ||= relation&.klass

    validate_language!(language)

    limit = Integer(limit)
    return (relation || SearchDocument.all).none if limit < 1

    sql = hybrid_search_internal(
      query,
      model: model,
      language: language,
      limit: limit,
      admin_mode: admin_mode,
      exact_mode: exact_mode,
      case_sensitive: case_sensitive,
      limit_ratio: limit_ratio
    )

    search_results = materialized_cte(
      :search_results, sql[:query], sql[:values]
    )

    if model.nil?
      # A document is one row per section and language already, so the
      # search results map to them one for one.
      SearchDocument.
        with(search_results: search_results).
        joins(
          "JOIN search_results " \
          "ON search_results.sd_id = search_documents.sd_id"
        ).
        order(Arel.sql("search_results.score DESC, search_documents.sd_id"))
    else
      record_id = "#{relation.quoted_table_name}." \
                  "#{relation.quoted_primary_key}"

      # A record can match through several translations or sections, so
      # roll the documents up to one row per record, scored by the best
      # of them. The relation stays chainable, countable and paginatable.
      search_records = materialized_cte(:search_records, <<~SQL.squish)
        SELECT searchable_type, searchable_id, max(score) AS score
        FROM search_results
        GROUP BY searchable_type, searchable_id
      SQL

      relation.
        with(search_results: search_results, search_records: search_records).
        joins(
          "JOIN search_records " \
          "ON search_records.searchable_type = '#{model}' " \
          "AND search_records.searchable_id = #{record_id}"
        ).
        order(Arel.sql("search_records.score DESC, #{record_id}"))
    end
  end

  # Run the full-text search over every document rooted at a request and
  # return the matching requests as a chainable relation: one row per
  # request, best hit first.
  #
  # +requests+ the requests the viewer may see. The public sees the
  #            searchable ones; a requester passes their own.
  # +limit+ caps the documents ranked, not the requests returned, so page
  #        the relation rather than passing a page size here.
  #
  # The search_requests CTE keeps each request's best hit as
  # searchable_type and searchable_id, for callers to select.
  def self.request_search(query, requests: InfoRequest.is_searchable,
                          language: nil, limit: 1000)
    validate_language!(language)

    limit = Integer(limit)
    return InfoRequest.none if limit < 1

    sql = hybrid_search_internal(
      query,
      model: Searchable.models_rooted_at(InfoRequest),
      language: language,
      limit: limit,
      admin_mode: false,
      exact_mode: false,
      case_sensitive: true,
      limit_ratio: 1
    )

    search_results = materialized_cte(
      :search_results, sql[:query], sql[:values]
    )

    search_requests = materialized_cte(
      :search_requests, <<~SQL.squish
        SELECT DISTINCT ON (root_id)
          root_id, score, searchable_type, searchable_id
        FROM search_results
        WHERE root_type = 'InfoRequest'
        ORDER BY root_id, score DESC, searchable_type, searchable_id
      SQL
    )

    requests.
      with(search_results: search_results, search_requests: search_requests).
      joins(
        "JOIN search_requests " \
        "ON search_requests.root_id = info_requests.id"
      ).
      order(Arel.sql("search_requests.score DESC, info_requests.id"))
  end

  def self.validate_language!(language)
    supported = Searchable.
      class_variable_get(:@@locale_to_language_map).
      values.
      concat(["simple", nil])
    return if supported.include?(language)

    raise(ArgumentError, "#{language} is not yet supported for search")
  end
  private_class_method :validate_language!

  # Requires: lib/core_ext/active_record_materialized_cte.rb
  def self.materialized_cte(name, query, values = {})
    Arel::Nodes::Cte.new(
      name, Arel.sql("(#{query})", **values), materialized: true
    )
  end
  private_class_method :materialized_cte
end
