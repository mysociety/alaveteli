# -*- encoding : utf-8 -*-
class AddUpdatedAtToInfoRequestEvents < ActiveRecord::Migration
  def up
    add_column :info_request_events, :updated_at, :datetime
  end

  def down
    remove_column :info_request_events, :updated_at
  end
end
