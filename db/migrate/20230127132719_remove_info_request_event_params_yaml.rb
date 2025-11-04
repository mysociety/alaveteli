class RemoveInfoRequestEventParamsYaml < ActiveRecord::Migration[7.0]
  def up
    if InfoRequestEvent.where(params: nil).any?
      raise <<~TXT
        We can't run the RemoveInfoRequestEventParamsYaml database migration.

        We have detected InfoRequestEvent objects which haven't been migrated
        to the new JSONB params column.

        Please deploy Alaveteli 0.42.0.0 and run the upgrade tasks:
        https://github.com/mysociety/alaveteli/blob/0.42.0.0/doc/CHANGES.md#upgrade-notes

      TXT
    end

    remove_column :info_request_events, :params_yaml
  end

  def down
    add_column :info_request_events, :params_yaml, :text
  end
end
