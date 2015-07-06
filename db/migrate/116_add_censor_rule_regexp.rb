# -*- encoding : utf-8 -*-
class AddCensorRuleRegexp < ActiveRecord::Migration
  def self.up
    add_column :censor_rules, :regexp, :boolean
  end

  def self.down
    remove_column :censor_rules, :regexp
  end
end
