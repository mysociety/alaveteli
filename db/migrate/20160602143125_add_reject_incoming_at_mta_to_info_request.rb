# -*- encoding : utf-8 -*-
class AddRejectIncomingAtMtaToInfoRequest < ActiveRecord::Migration[4.2] # 3.2
 def up
    add_column :info_requests, :reject_incoming_at_mta, :boolean, :default => false, :null => false
  end

  def down
    remove_column :info_requests, :reject_incoming_at_mta
  end
end
