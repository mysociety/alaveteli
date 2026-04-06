class AddSearchDocument < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'vector'

    create_table "search_documents", force: :cascade do |t|
      t.belongs_to :searchable_doc, polymorphic: true
      t.text     :raw_content # extracted via tika/etc...
      t.text     :section_ref # page/sheet name/...

      # Full text search
      # we need to store tsvectors because unaccent is not immutable
      # so it can't be used in the index definition
      t.column   :content_tsv, :tsvector
      t.column   :language, :text
      # semantic search is in raw sql as this does not work
      # without "neighbor" gem
      # t.column   :embedding, :vector, limit: 384

      # TODO: add trigram index to help suggest spelling corrections
      # see https://www.postgresql.org/docs/18/pgtrgm.html#PGTRGM-TEXT-SEARCH

      t.timestamps
    end

    # TODO: fill embeddings with
    # https://github.com/ankane/transformers-ruby?tab=readme-ov-file#sentence-transformersmulti-qa-MiniLM-L6-cos-v1
    # (same model as previous experiment in python)
    reversible do |direction|
      direction.up do
        execute <<-SQL
          alter table search_documents add column
            embedding vector(384);

          -- reciprocal ranked fusion
          CREATE OR REPLACE FUNCTION rrf_score(rank bigint, rrf_k bigint DEFAULT 50)
          RETURNS numeric
          LANGUAGE SQL
          IMMUTABLE PARALLEL SAFE
          AS $$
              SELECT COALESCE(1.0 / ($1 + $2), 0.0);
          $$ ;

          CREATE OR REPLACE FUNCTION update_search_document_tsv()
          RETURNS TRIGGER AS $$
          BEGIN
            UPDATE search_documents
            SET content_tsv = (
              SELECT to_tsvector(language::regconfig, coalesce(unaccent(raw_content), ''))
              FROM search_documents
              WHERE id = NEW.id
            )
            WHERE id = NEW.id;

            RETURN NEW;
          END;
          $$ LANGUAGE plpgsql;

          CREATE TRIGGER search_documents_content_tsv_trigger
          AFTER INSERT OR UPDATE OF raw_content ON search_documents
          FOR EACH ROW
          EXECUTE FUNCTION update_search_document_tsv();
        SQL
      end
      direction.down do
        execute <<-SQL
          alter table search_documents drop column embedding;
          drop function update_search_document_tsv;
        SQL
      end
    end

    # size TBC
    add_index :search_documents, :embedding, using: :hnsw, opclass: :vector_cosine_ops

    # 31MB
    add_index(:search_documents, :content_tsv, using: :gin)

    # 158MB
    add_index(:search_documents, :raw_content, using: :gin, opclass: :gin_trgm_ops)
  end
end
