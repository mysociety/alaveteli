class AddInfoRequestEventIndexingFunction < ActiveRecord::Migration[8.0]
  def up
    execute(
      <<-SQL
      CREATE OR REPLACE FUNCTION cleanup_jsonb_for_search(json_v jsonb)
      -- simplify jsonb columns to keep only values that are likely to be searched.
      -- This excludes keys, timestamps and references to other objects.
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

  def down
    execute(
      <<-SQL
      DROP FUNCTION IF EXISTS cleanup_jsonb_for_search;
      SQL
    )
  end
end
