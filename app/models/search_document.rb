# the smallest "thing" we can search for (in info requests,
# incoming/outgoing messages and attachments)
# Can be a paragraph, a page, a sheet in a spreadsheet, or
# an entire file depending on how each class defines its
# search capabilities
# == Schema Information
#
# Table name: search_documents
#
#  id                  :bigint           not null, primary key
#  searchable_doc_type :string
#  searchable_doc_id   :bigint
#  raw_content         :text
#  section_ref         :text
#  content_tsv         :tsvector
#  language            :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  embedding           :vector(384)
#
class SearchDocument < ApplicationRecord
  belongs_to :searchable_doc, polymorphic: true

  @@model = Transformers.pipeline("embedding", "sentence-transformers/multi-qa-MiniLM-L6-cos-v1")

  def self.init_raw_content
    # 280ms to load 15k incoming_messages
    # 850ms for 72k IM+OM
    # 39s with GIN indexes (todo: drop index then reindex after loading)
    sql = <<-SQL
      ALTER TABLE search_documents DISABLE TRIGGER search_documents_content_tsv_trigger;

      with incoming_msg AS (
        select
          'IncomingMessage' as searchable_doc_type,
          id as searchable_doc_id,
          cached_main_body_text_unfolded as raw_content,
          'french' as language,
          now()::timestamp as created_at,
          now()::timestamp as updated_at
        from incoming_messages
      ),
      outgoing_msg AS (
        select
          'OutgoingMessage' as searchable_doc_type,
          id as searchable_doc_id,
          body as raw_content,
          'french' as language,
          now()::timestamp as created_at,
          now()::timestamp as updated_at
        from outgoing_messages
      )
      insert into search_documents
        (searchable_doc_type, searchable_doc_id, raw_content, language, created_at, updated_at)
      (select * from incoming_msg union select * from outgoing_msg);

      ALTER TABLE search_documents ENABLE TRIGGER search_documents_content_tsv_trigger;
    SQL
    ActiveRecord::Base.connection.execute(sql)
  end

  def self.init_content_tsv
    # ugly backfill for testing
    # 6-7s to backfill 15k incoming_messages
    # 26s for 72k IM+OM
    # 78s with GIN indexes
    sql = <<-SQL
      ALTER TABLE search_documents DISABLE TRIGGER search_documents_content_tsv_trigger;
      UPDATE search_documents sd
      SET content_tsv = (
        SELECT to_tsvector(language::regconfig, coalesce(unaccent(raw_content), ''))
        FROM search_documents
        WHERE id = sd.id
      );
      ALTER TABLE search_documents ENABLE TRIGGER search_documents_content_tsv_trigger;
    SQL
    ActiveRecord::Base.connection.execute(sql)
  end

  def self.init_semantic_vectors(limit = 1)
    # simple backfill to generate semantic vectors using transformers-rb
    t0 = Time.now
    loading_t = Time.now
    # this model is trained on 250 words text bits max, and truncates input text
    # at 512 words, so we need to slice longer test before getting here
    # (500 words is about 1 page of text)
    # https://huggingface.co/sentence-transformers/multi-qa-MiniLM-L6-cos-v1#intended-uses
    embed_t = 0
    db_t = 0
    failed = 0
    where(embedding: nil).limit(limit).each do |doc|
      # this randomly fails when the string *appears to contain too many words*
      # (it's not a char limit)
      begin
        t1 = Time.now
        # in practice, text longer than about 1600 chars fails to embed, but no
        # clear error message, will need investigating, might be model dependent
        doc_embedding = @@model.call(doc.raw_content[0..1600])
        t2 = Time.now
        # using the neighbor gem is an option instead of to_s
        doc.update(embedding: doc_embedding.to_s)
        t3 = Time.now
        embed_t += (t2 - t1)
        db_t += (t3 - t2)
      rescue
        puts "Failed to embed doc.id #{doc.id}"
        failed += 1
      end
    end
    puts "Load model: #{(loading_t - t0).round(2)} s"
    puts "Embedding: #{embed_t.round(3)} s (#{(1000 * embed_t / limit).round(4)} ms / record)"
    puts "DB update: #{db_t.round(3)} s"
    puts "Failed to embed #{failed} / #{limit} records"
    limit
  end

  def self.hybrid_search_internal(query, doc_type = nil, lang = 'french', semantic_threshold = 0.6)
    search_terms = query.
      split(' ').
      map { |q| "to_tsquery('#{lang}', unaccent(COALESCE('#{q}', '')))" }.
      join(' && ')

    if doc_type.nil?
      doc_type_q = "(1=1)"
    else
      doc_type_q = "searchable_doc_type = '#{doc_type}'"
    end

    q_embedding = @@model.call(query)

    sql = <<-SQL
      SELECT
      searches.id,
      searches.raw_content,
      sum(searches.rank) AS rank_sum,
      sum(rrf_score(searches.rank)) AS score
      FROM (
      (
          SELECT
              id,
              raw_content,
              rank() OVER (ORDER BY '#{q_embedding}'::vector <=> embedding) AS rank
          FROM search_documents
          WHERE embedding is not null
          AND ('#{q_embedding}'::vector <=> embedding) < #{semantic_threshold}
          ORDER BY '#{q_embedding}'::vector <=> embedding
          LIMIT 40
      )
      UNION ALL
      (
          SELECT
              id,
              raw_content,
              rank() OVER (
                ORDER BY ts_rank_cd(content_tsv, plainto_tsquery('#{query}')) DESC
              ) AS rank
          FROM search_documents
          WHERE
              plainto_tsquery('#{lang}', '#{query}') @@ content_tsv
          ORDER BY rank
          LIMIT 40
      )
      ) searches
      GROUP BY searches.id, searches.raw_content
      ORDER BY score DESC
      LIMIT 10
    SQL

    sql
  end

  def self.word_distance(w1, w2)
    # just for debugging, helps understand cosine distance between 2 words/sentences
    q1_embedding = @@model.call(w1)
    q2_embedding = @@model.call(w2)
    sql = <<-SQL
      SELECT
          (#{q1_embedding}::vector <=> #{q2_embedding}::vector) AS dist
    SQL
    sql
  end

  def self.hybrid_search(query, doc_type = nil, lang = 'french')
    # chainable call
    sql = hybrid_search_internal(query, doc_type, lang)
    SearchDocument.where("id IN (SELECT s.id FROM (#{sql}) s)")
  end

  def self.search(query, doc_type = nil, lang = 'french')
    # This returns a chainable ActiveRecord object, and produces a single SQL
    # query.
    # There are certainly ways to optimise this and secure it against injection,
    # and make it more elegant. Also curious about the ORM overhead.
    search_terms = query.
      split(' ').
      map { |q| "to_tsquery('#{lang}', unaccent(COALESCE('#{q}', '')))" }.
      join(' && ')

    if doc_type.nil?
      doc_type_q = "(1=1)"
    else
      doc_type_q = "searchable_doc_type = '#{doc_type}'"
    end

    sql = <<-SQL
      SELECT
        "search_documents".id FROM "search_documents" INNER JOIN (
        SELECT
          "search_documents"."id" AS search_id,
          (ts_rank(("search_documents"."content_tsv"), (#{search_terms})), 0) AS rank
        FROM "search_documents"
        WHERE
          (("search_documents"."content_tsv") @@ (#{search_terms}))
          AND #{doc_type_q}
        ) AS subreq
      ON
        "search_documents"."id" = subreq.search_id
      ORDER BY
        subreq.rank DESC,
        "search_documents"."id" ASC
    SQL

    SearchDocument.where("id IN (#{sql})")
  end


end

# volumes:
# IM: 83MB
# OM: 102MB
# tot: 185MB
# SD: 123MB without tsv
#     340MB with tsv  (one record per IM/OM) ~2x IM+OM
# indexes: see migration
