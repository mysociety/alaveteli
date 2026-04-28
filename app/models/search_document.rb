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
#  section_ref         :text
#  language            :text
#  content_tsv         :tsvector
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
class SearchDocument < ApplicationRecord
  belongs_to :searchable_doc, polymorphic: true
  self.primary_key = [:sd_id, :searchable_doc_type]

  # Do not use hybrid_search_internal directly as it does NOT sanitize
  # query, and is susceptible to injection. Use hybrid_search instead.
  def self.hybrid_search_internal(
    query,
    model:,
    language:,
    limit:,
    admin_mode:,
    semantic_threshold:,
    limit_ratio:
  )
    Rails.logger.debug(
      "Searching for '#{query}' through #{model} in lang #{language}"
    )
    search_terms = query.
      split(" ").
      map { |q| "to_tsquery('#{language}', unaccent(COALESCE('#{q}', '')))" }.
      join(" && ")

    if model.nil?
      doc_type_q = "(1=1)"
    else
      doc_type_q = "searchable_doc_type = '#{model}'"
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
        WHERE embedding is not null
            AND #{doc_type_q}
            AND ('#{q_embedding}'::vector <=> embedding) < #{semantic_threshold}
        ORDER BY '#{q_embedding}'::vector <=> embedding
        LIMIT #{limit * limit_ratio}
        SQL
    end

    if admin_mode
      search_queries << <<-SQL
          SELECT
              sd_id,
              rank() OVER (
                ORDER BY ts_rank_cd(admin_content_tsv, plainto_tsquery(#{query})) DESC
              ) AS rank
          FROM search_documents
          WHERE
              plainto_tsquery('simple', #{query}) @@ admin_content_tsv
              AND #{doc_type_q}
          ORDER BY rank
          LIMIT #{limit * limit_ratio}
        SQL
    end

    search_queries << <<-SQL
        SELECT
            sd_id,
            rank() OVER (
              ORDER BY ts_rank_cd(content_tsv, plainto_tsquery(#{query})) DESC
            ) AS rank
        FROM search_documents
        WHERE
            plainto_tsquery('#{language}', #{query}) @@ content_tsv
            AND #{doc_type_q}
        ORDER BY rank
        LIMIT #{limit * limit_ratio}
      SQL

    sql = <<-SQL
      SELECT
        searches.sd_id,
        sum(searches.rank) AS rank_sum,
        sum(rrf_score(searches.rank)) AS score
      FROM ((#{search_queries.join(") UNION ALL (")})) searches
      GROUP BY searches.sd_id
      ORDER BY score DESC
      LIMIT #{limit}
    SQL

    sql
  end

  def self.hybrid_search(query,
                         model: nil,
                         language: nil,
                         limit: 10,
                         admin_mode: false,
                         semantic_threshold: 0.6,
                         limit_ratio: 3)
    sql = hybrid_search_internal(
      ActiveRecord::Base.connection.quote(query),
      model: model,
      language: language,
      limit: limit,
      admin_mode: admin_mode,
      semantic_threshold: semantic_threshold,
      limit_ratio: limit_ratio
    )
    if model.nil?
      SearchDocument.where("sd_id IN (SELECT s.sd_id FROM (#{sql}) s)")
    else
      model.with(search_results: Arel.sql(sql)).
            joins(:search_documents).
            joins(
              "JOIN search_results " \
              "ON search_results.sd_id = search_documents.sd_id"
            )
    end
  end
end
