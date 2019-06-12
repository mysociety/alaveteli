# -*- encoding : utf-8 -*-
class AddProminence < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 2.0
  def self.up
    add_column :info_requests, :prominence, :string, :null => false, :default => 'normal'
  end

  def self.down
    remove_column :info_requests, :prominence
  end
end
