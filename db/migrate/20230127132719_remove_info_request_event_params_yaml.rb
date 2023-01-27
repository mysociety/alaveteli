class RemoveInfoRequestEventParamsYaml < ActiveRecord::Migration[7.0]
  def change
    remove_column :info_request_events, :params_yaml, :text
  end
end
