class AddSearchDocument < ActiveRecord::Migration[8.0]
  # model names are hardcoded rather than referencing the classes so the
  # migration keeps working even if application models are later renamed
  # or removed.
  MODELS_FOR_SEARCH_DOCUMENT_PARTITIONS = %w[
    CensorRule
    Citation
    Comment
    User::EmailHistory
    FoiAttachment
    IncomingMessage
    InfoRequest
    InfoRequestEvent
    OutgoingMessage
    MailServerLog
    Note
    PublicBody
    PublicBodyChangeRequest
    User
  ].freeze

  def change
    # partition the search table by doctype/model. For bigger deployments,
    # this should result in faster search for public bodies (which is likely to be
    # very common) because the index for that table can stay in memory. Searches for
    # messages/attachments will also benefit as we end up with somewhat smaller
    # indices there too.
    # On smaller deployments, it shouldn't really make a difference.
    create_table(
      "search_documents",
      primary_key: [:searchable_type, :sd_id],
      force: :cascade,
      options: "PARTITION BY LIST (searchable_type)"
    ) do |t|
      t.bigserial(:sd_id)
      t.belongs_to(:searchable, polymorphic: true)
      # plain text content of the related document.
      # This might come from a text extraction tool (for attachments),
      # but might also be a direct copy of admin_index fields to allow
      # admins to do an exact text search.
      t.text(:raw_content)
      t.text(:raw_admin_content)
      # page/sheet name/...
      t.text(:section_ref)

      # this is the postgres language, which is not the same as the locale
      # that ruby knows.
      t.column(:language, :text)

      # Full text search
      # we need to store tsvectors because unaccent is not immutable
      # so it can't be used in the index definition. This allows support
      # for accented languages.
      t.column(:content_tsv, :tsvector)

      # similar tsvector but for data that is only admin-visible.
      # The fields in `admin_index` are used to populate this column.
      # This is mainly used for GDPR-type search where an admin needs
      # to find all occurrences of a name, email, etc...
      t.column(:admin_content_tsv, :tsvector)

      # we don't really need these, include them while developing to help
      # with debugging, but drop them once we're more comfortable with the
      # way the search works
      t.timestamps
    end

    reversible do |direction|
      direction.up do
        # do not drop the extension on the way down, as it may be used elsewhere
        # by local setups
        execute("create extension if not exists unaccent")

        # create a table partition for each model.
        MODELS_FOR_SEARCH_DOCUMENT_PARTITIONS.each do |model|
          execute(
            <<-SQL
              CREATE TABLE IF NOT EXISTS #{partition_table_name(model)}
                PARTITION OF search_documents
                FOR VALUES IN ('#{model}');
            SQL
          )
        end

        execute(
          <<-SQL
          -- reciprocal ranked fusion
          CREATE OR REPLACE FUNCTION rrf_score(rank bigint, rrf_k bigint DEFAULT 50)
          RETURNS numeric
          LANGUAGE SQL
          IMMUTABLE PARALLEL SAFE
          AS $$
              SELECT COALESCE(1.0 / ($1 + $2), 0.0);
          $$ ;

          -- simplify jsonb columns to keep only values that are likely to be searched.
          -- This excludes keys, timestamps and references to other objects.
          CREATE OR REPLACE FUNCTION cleanup_jsonb_for_search(json_v jsonb)
          RETURNS text
          LANGUAGE SQL
          IMMUTABLE PARALLEL SAFE
          AS $$
            SELECT string_agg(v, ' ' ORDER BY k)
            FROM jsonb_each_text(json_v) AS x(k,v)
            WHERE k NOT IN (
              'described_state',
              'embargo',
              'event_created_at',
              'incoming_message',
              'old_described_state',
              'outgoing_message',
              'user'
            )
          $$;
          SQL
        )
      end

      direction.down do
        execute(
          <<-SQL
          DROP FUNCTION IF EXISTS rrf_score;
          DROP FUNCTION IF EXISTS cleanup_jsonb_for_search;
          SQL
        )

        # drop the same partitions that were created on the way up, so the
        # rollback does not depend on which models are currently registered
        # as searchable in the application.
        MODELS_FOR_SEARCH_DOCUMENT_PARTITIONS.each do |model|
          execute(
            <<-SQL
              DROP TABLE IF EXISTS #{partition_table_name(model)};
            SQL
          )
        end
      end
    end

    # the indices below are declared on the main table, but a matching index is
    # automatically created on each partition by postgres.
    add_index(:search_documents, [:searchable_type, :searchable_id, :section_ref, :language], unique: true)

    # supports FTS
    add_index(:search_documents, :content_tsv, using: :gin)
    add_index(:search_documents, :admin_content_tsv, using: :gin)
  end

  private

  def partition_table_name(model)
    "search_documents_#{model.downcase.gsub('::', '_')}"
  end
end
