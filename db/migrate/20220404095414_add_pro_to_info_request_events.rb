class AddProToInfoRequestEvents < ActiveRecord::Migration[6.1]
  def change
    add_column :info_request_events, :pro, :boolean, default: false
  end
end
