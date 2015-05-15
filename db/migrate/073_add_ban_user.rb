# -*- encoding : utf-8 -*-
class AddBanUser < ActiveRecord::Migration
    def self.up
        add_column :users, :ban_text, :text, :null => false, :default => ""
    end

    def self.down
        remove_column :users, :ban_text
    end
end

