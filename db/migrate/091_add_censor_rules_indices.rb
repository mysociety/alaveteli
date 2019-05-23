# -*- encoding : utf-8 -*-
class AddCensorRulesIndices < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 2.3
  def self.up
    add_index :censor_rules, :info_request_id
    add_index :censor_rules, :user_id
    add_index :censor_rules, :public_body_id
  end

  def self.down
    raise "no down"
  end
end
