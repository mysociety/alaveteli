# -*- encoding : utf-8 -*-
class AddLawUsed < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 2.0
  def self.up
    add_column :info_requests, :law_used, :string, :null => false, :default => 'foi'
  end

  def self.down
    remove_column :info_requests, :law_used
  end
end
