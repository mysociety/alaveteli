# -*- encoding : utf-8 -*-
class AddCanMakeBatchRequestsToUser < ActiveRecord::Migration[4.2] # 3.2
  def change
    add_column :users, :can_make_batch_requests, :boolean, :default => false, :null => false
  end
end
