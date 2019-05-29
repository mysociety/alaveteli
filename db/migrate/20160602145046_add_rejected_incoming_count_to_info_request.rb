# -*- encoding : utf-8 -*-
class AddRejectedIncomingCountToInfoRequest < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 3.2
  def up
    add_column :info_requests, :rejected_incoming_count, :integer, :default => 0
  end

  def down
    remove_column :info_requests, :rejected_incoming_count
  end
end
