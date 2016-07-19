# -*- encoding : utf-8 -*-
class AddRejectedIncomingCountToInfoRequest < ActiveRecord::Migration
  def up
    add_column :info_requests, :rejected_incoming_count, :integer, :default => 0
  end

  def down
    remove_column :info_requests, :rejected_incoming_count
  end
end
