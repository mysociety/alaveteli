class AddMailServerLogCleanupFunctions < ActiveRecord::Migration[8.0]
  def up
    # note that the regexps below require double backslashes for postgres
    # to interpret them correctly. so '\\[` is interpreted as '\[` by pg
    execute(
      <<-SQL
      CREATE OR REPLACE FUNCTION cleanup_mail_server_logs_for_search_with_postfix(logline text, server_name text)
      RETURNS text
      LANGUAGE SQL
      IMMUTABLE PARALLEL SAFE
      AS $$
        SELECT string_agg(emails, ' ')
        FROM (
          SELECT distinct
            array_to_string(
              regexp_matches(
                logline,
                '<([^>]+?@[^>]+?\.\\w{2,25})>|relay=([^\\[]+?)\\[',
                'g'
              ),
            ' '
          ) as emails) q
        WHERE emails NOT LIKE concat('%', server_name)
      $$;
      SQL
    )
    execute(
      <<-SQL
      CREATE OR REPLACE FUNCTION cleanup_mail_server_logs_for_search_with_exim(logline text, server_name text)
      RETURNS text
      LANGUAGE SQL
      IMMUTABLE PARALLEL SAFE
      AS $$
        SELECT string_agg(emails, ' ')
        FROM (
          SELECT distinct
            array_to_string(
              regexp_matches(
                logline,
                '<([^> ]+?@[^> ]+?\..{2,25})>| for (.+?)$| H=([^ ]+?) | T="([^"]+?)" ',
                'g'
              ),
            ' '
          ) as emails) q
        WHERE emails NOT LIKE concat('%', server_name)
      $$;
      SQL
    )
    execute(
      <<-SQL
      CREATE OR REPLACE FUNCTION cleanup_mail_server_logs_for_search(logline text, mta_type text, server_name text)
      -- cleanup mail server log lines to keep only PII information
      -- args:
      -- logline: the text from the 'line' column
      -- mta_type: exim or postfix, from MTA_LOG_TYPE alaveteli config
      -- server_name: domain name of the alaveteli mail server, used to ignore internal addresses
      RETURNS text
      LANGUAGE SQL
      IMMUTABLE PARALLEL SAFE
      AS $$
        SELECT
          CASE
          WHEN mta_type='exim' THEN cleanup_mail_server_logs_for_search_with_exim(logline, server_name)
          WHEN mta_type='postfix' THEN cleanup_mail_server_logs_for_search_with_postfix(logline, server_name)
          ELSE ''
        END
      $$;
      SQL
    )
  end

  def down
    execute(
      <<-SQL
      DROP FUNCTION IF EXISTS cleanup_mail_server_logs_for_search;
      DROP FUNCTION IF EXISTS cleanup_mail_server_logs_for_search_with_exim;
      DROP FUNCTION IF EXISTS cleanup_mail_server_logs_for_search_with_postfix;
      SQL
    )
  end
end
