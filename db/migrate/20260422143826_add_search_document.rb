class AddSearchDocument < ActiveRecord::Migration[8.0]
  def change

    # make sure all models (OutgoingMessage in particular) are loaded
    # so we don't miss any partition.
    Rails.application.eager_load!

    # enable_extension 'vector'

    # partition the search table by doctype/model. For bigger deployments,
    # this should result in faster search for public bodies (which is likely to be
    # very common) because the index for that table can stay in memory. Searches for
    # messages/attachments will also benefit as we end up with somewhat smaller
    # indices there too.
    # On smaller deployments, it shouldn't really make a difference.
    create_table(
      "search_documents",
      primary_key: [:searchable_doc_type, :sd_id],
      force: :cascade,
      options: "PARTITION BY LIST (searchable_doc_type)"
    ) do |t|
      t.bigserial(:sd_id)
      # TODO: can searchable_doc_type be changed to an enum
      # to reduce storage size?
      t.belongs_to(:searchable_doc, polymorphic: true)
      # plain text content of the related document.
      # This might come from a text extraction tool (for attachments),
      # but might also be a direct copy of admin_index fields to allow
      # admins to do an exact text search.
      t.text(:raw_content)
      # page/sheet name/...
      t.text(:section_ref)

      # Full text search
      # we need to store tsvectors because unaccent is not immutable
      # so it can't be used in the index definition
      t.column(:language, :text)
      t.column(:content_tsv, :tsvector)

      # semantic search is in raw sql below as this does not work
      # without the "neighbor" gem (which seems to add syntactic sugar only,
      # so isn't worth the extra surface)

      # TODO: add trigram index to help suggest spelling corrections
      # see https://www.postgresql.org/docs/18/pgtrgm.html#PGTRGM-TEXT-SEARCH

      # we don't really need these, include them while developing to help
      # with debugging, but drop them once we're more comfortable with the
      # way the search works
      t.timestamps
    end

    reversible do |direction|
      direction.up do
        # create a table partition for each model.
        say("#{Searchable.class_variable_get(:@@searchable_models)}")
        Searchable.class_variable_get(:@@searchable_models).keys.each do |model|
          say("#{model}", true)
          execute(
            <<-SQL
              CREATE TABLE IF NOT EXISTS search_documents_#{model.downcase}
                PARTITION OF search_documents
                FOR VALUES IN ('#{model}');
            SQL
          )
        end

        # TODO: fill embeddings with
        # https://github.com/ankane/transformers-ruby?tab=readme-ov-file#sentence-transformersmulti-qa-MiniLM-L6-cos-v1
        execute(
          <<-SQL
          -- TODO: decide on vector dimension
          -- this requires the pgvector extension (called 'vector' inside pg)
          alter table search_documents add column
            embedding vector(384);

          -- auto update the content_tsv column whenever the raw_content
          -- is modified so that data stays in sync. The index is updated
          -- automatically as well.
          -- FIXME: this does not work when searchable.index contains
          -- keys with different weight. Is this trigger even useful?
          -- CREATE OR REPLACE FUNCTION update_search_document_tsv()
          -- RETURNS TRIGGER AS $$
          -- BEGIN
          --   UPDATE search_documents
          --   SET content_tsv = (
          --     SELECT to_tsvector(language::regconfig, coalesce(unaccent(raw_content), ''))
          --     FROM search_documents
          --     WHERE id = NEW.id
          --   )
          --   WHERE id = NEW.id;
          --
          --   RETURN NEW;
          -- END;
          -- $$ LANGUAGE plpgsql;
          --
          -- CREATE TRIGGER search_documents_content_tsv_trigger
          --   AFTER INSERT OR UPDATE OF raw_content ON search_documents
          --   FOR EACH ROW
          --   EXECUTE FUNCTION update_search_document_tsv();
          SQL
        )
      end

      direction.down do
        execute(
          <<-SQL
          DROP TRIGGER IF EXISTS
            search_documents_content_tsv_trigger
            ON search_documents;
          DROP FUNCTION IF EXISTS update_search_document_tsv;
          ALTER TABLE search_documents DROP COLUMN embedding;
          SQL
        )

        Searchable.class_variable_get(:@@searchable_models).keys.each do |model|
          execute(
            <<-SQL
              DROP TABLE IF EXISTS search_documents_#{model.downcase};
            SQL
          )
        end
      end
    end

    # the indices below are declared on the main table, but a matching index is
    # automatically created on each partition automatically by postgres.

    add_index(:search_documents, [:searchable_doc_type, :searchable_doc_id, :section_ref, :language], unique: true)

    # supports semantic search using cosine similarity
    add_index(:search_documents, :embedding, using: :hnsw, opclass: :vector_cosine_ops)

    # supports FTS
    add_index(:search_documents, :content_tsv, using: :gin)
    # used by typo suggestions. This index is rather heavy to maintain, so it is
    # disabled for now
    # add_index(:search_documents, :raw_content, using: :gin, opclass: :gin_trgm_ops)
  end
end
