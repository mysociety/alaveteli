class AddJsonbColumnToInfoRequestEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :info_request_events, :params, :jsonb
    add_index  :info_request_events, :params, using: :gin
  end
end
