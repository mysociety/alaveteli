# -*- encoding : utf-8 -*-
class AddUpdatedAtToInfoRequestEvents < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def up
    add_column :info_request_events, :updated_at, :datetime
  end

  def down
    remove_column :info_request_events, :updated_at
  end
end
