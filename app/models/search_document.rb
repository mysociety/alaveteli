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
#  sd_id             :bigint           not null, primary key
#  searchable_type   :string           not null, primary key
#  searchable_id     :bigint
#  section_ref       :text
#  language          :text
#  content_tsv       :tsvector
#  admin_content_tsv :tsvector
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  raw_content       :jsonb
#  raw_admin_content :jsonb
#
class SearchDocument < ApplicationRecord
  belongs_to :searchable, polymorphic: true
  self.primary_key = [:searchable_type, :sd_id]

  DEFAULT_RANK_WEIGHTS = {
    'A' => 1.0, 'B' => 0.4, 'C' => 0.2, 'D' => 0.1
  }.freeze

  INDEX_TSV_COLUMNS = {
    index: 'content_tsv', admin_index: 'admin_content_tsv'
  }.freeze

  INDEX_RAW_COLUMNS = {
    index: 'raw_content', admin_index: 'raw_admin_content'
  }.freeze

  # build the sql query for the search. This should be injection-safe.
  def self.hybrid_search_internal(
    query,
    model:,
    language:,
    limit:,
    admin_mode:,
    exact_mode:,
    case_sensitive:,
    limit_ratio:,
    weights: nil,
    except: nil
  )
    # coerce values that are interpolated into the SQL rather than bound,
    # so a non-numeric value raises instead of reaching the query.
    limit = Integer(limit)
    limit_ratio = Integer(limit_ratio)
    weights_literal = rank_weights_literal(weights)

    # A search matches against one index, and +admin_mode+ says which:
    # admin_content_tsv for an admin search, content_tsv otherwise. The index
    # an excluded label belongs to is therefore this flag rather than
    # something the caller has to key by hand.
    except = Array(except)
    admin_except = admin_mode ? except : []
    content_except = admin_mode ? [] : except

    admin_tsv = tsv_expression(:admin_index, admin_except)
    content_tsv = tsv_expression(:index, content_except)
    admin_recheck_q = label_recheck_q(:admin_index, admin_tsv)
    content_recheck_q = label_recheck_q(:index, content_tsv)

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
              rank() OVER (
                ORDER BY ts_rank_cd(#{weights_literal}, #{admin_tsv}, websearch_to_tsquery(:language, unaccent(:query))) DESC
              ) AS rank
          FROM search_documents
          WHERE
              websearch_to_tsquery(:language, unaccent(:query)) @@ admin_content_tsv
              #{admin_recheck_q}
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

      # The raw_* columns store the indexed text keyed by the tsvector label it
      # was weighted with, so the substring search skips the labels the caller
      # excluded rather than skipping the whole column.
      like_conditions = raw_label_predicates(:index, content_except, like_op)
      if admin_mode
        like_conditions += raw_label_predicates(
          :admin_index, admin_except, like_op
        )
      end

      search_queries << <<~SQL.chomp
        SELECT
          sd_id,
          rank() OVER (ORDER BY sd_id DESC) AS rank
        FROM search_documents
        WHERE
          (#{like_conditions.join(' OR ')})
          #{doc_type_q}
        LIMIT #{limit * limit_ratio}
      SQL
    end

    # all searches use the FTS ts_vectors
    search_queries << <<~SQL.chomp
        SELECT
            sd_id,
            rank() OVER (
              ORDER BY ts_rank_cd(#{weights_literal}, #{content_tsv}, websearch_to_tsquery(:language, unaccent(:query))) DESC
            ) AS rank
        FROM search_documents
        WHERE
            websearch_to_tsquery(:language, unaccent(:query)) @@ content_tsv
            #{content_recheck_q}
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
  # +weights+ an optional label => weight hash overriding the numeric weight
  #           each tsvector label (A/B/C/D) contributes to relevance ranking.
  #           Missing labels fall back to DEFAULT_RANK_WEIGHTS.
  # +except+ an optional list of tsvector labels to remove from the index this
  #          search matches against, so they contribute to neither matching nor
  #          ranking. Which index that is follows +admin_mode+, as a label
  #          means different things in each. Searchable's +except+ takes the
  #          indexed field names instead and resolves them to labels against
  #          the same index, which is what callers outside this class want.
  #
  #          Excluding labels also narrows +exact_mode+'s substring search
  #          rather than disabling it: the raw column it reads is keyed by the
  #          same labels, so the excluded text is skipped there too while the
  #          rest of the column stays searchable.
  def self.hybrid_search(query,
                         relation: nil,
                         model: nil,
                         language: nil,
                         limit: 10,
                         admin_mode: false,
                         exact_mode: false,
                         case_sensitive: true,
                         limit_ratio: 3,
                         weights: nil,
                         except: nil)
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

    supported_langs = Searchable.
      class_variable_get(:@@locale_to_language_map).
      values.
      concat(
        [
          "simple",
          nil
        ]
      )
    unless supported_langs.include?(language)
      raise(ArgumentError, "#{language} is not yet supported for search")
    end

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
      limit_ratio: limit_ratio,
      weights: weights,
      except: except
    )

    if model.nil?
      SearchDocument.where("sd_id IN (SELECT s.sd_id FROM (#{sql[:query]}) s)",
sql[:values])
    else
      scoped = relation.
        with(search_results: Arel.sql(sql[:query], **sql[:values])).
        joins(:search_documents).
        joins(
          "JOIN search_results " \
          "ON search_results.sd_id = search_documents.sd_id"
        )

      # De-duplicate records that match through several translations or
      # sections (the join yields one row per matching search_document).
      # DISTINCT keeps the relation chainable, countable and paginatable;
      # a faster DISTINCT ON (id) is not expressible through the ORM without
      # losing those properties.
      scoped.distinct
    end
  end

  # Build an injection-safe '{D,C,B,A}'::float4[] literal for ts_rank_cd
  def self.rank_weights_literal(weights)
    weights = (weights || {}).transform_keys(&:to_s)
    unknown = weights.keys - DEFAULT_RANK_WEIGHTS.keys
    unless unknown.empty?
      raise(
        ArgumentError,
        "unknown tsvector label(s) in weights: #{unknown.join(', ')}"
      )
    end

    merged = DEFAULT_RANK_WEIGHTS.merge(weights)
    ordered = %w[D C B A].map { |label| Float(merged.fetch(label)) }
    "'{#{ordered.join(',')}}'::float4[]"
  end
  private_class_method :rank_weights_literal

  # The tsvector expression to match and rank against for +index+, with any
  # excluded labels removed by ts_filter
  def self.tsv_expression(index, except_labels)
    column = INDEX_TSV_COLUMNS.fetch(index)
    excluded = Array(except_labels).map { |label| label.to_s.upcase }
    unknown = excluded - DEFAULT_RANK_WEIGHTS.keys
    unless unknown.empty?
      raise(
        ArgumentError,
        "unknown tsvector label(s) to exclude: #{unknown.join(', ')}"
      )
    end

    return column if excluded.empty?

    kept = DEFAULT_RANK_WEIGHTS.keys - excluded
    if kept.empty?
      raise(
        ArgumentError,
        "cannot exclude every tsvector label from the #{index} search"
      )
    end

    # ts_filter takes lowercase labels
    "ts_filter(#{column}, '{#{kept.map(&:downcase).join(',')}}')"
  end
  private_class_method :tsv_expression

  # An extra narrowing of matches to the labels that aren't exclude
  def self.label_recheck_q(index, tsv_expr)
    return '' if tsv_expr == INDEX_TSV_COLUMNS.fetch(index)

    "AND websearch_to_tsquery(:language, unaccent(:query)) @@ #{tsv_expr}"
  end
  private_class_method :label_recheck_q

  # A substring predicate for each label of +index+'s raw column that aren't
  # excluded.
  def self.raw_label_predicates(index, except_labels, like_op)
    column = INDEX_RAW_COLUMNS.fetch(index)
    excluded = Array(except_labels).map { |label| label.to_s.upcase }
    kept = DEFAULT_RANK_WEIGHTS.keys - excluded

    kept.map { |label| "#{column} ->> '#{label}' #{like_op} :like_query" }
  end
  private_class_method :raw_label_predicates
end
