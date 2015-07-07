# -*- encoding : utf-8 -*-
class AddCanMakeBatchRequestsToUser < ActiveRecord::Migration
  def change
      add_column :users, :can_make_batch_requests, :boolean, :default => false, :null => false
  end
end
