# -*- encoding : utf-8 -*-
class AddCharityNumber < ActiveRecord::Migration
    def self.up
        add_column :public_bodies, :charity_number, :text, :null => false, :default => ""
        add_column :public_body_versions, :charity_number, :text, :null => false, :default => ""
    end

    def self.down
        remove_column :public_bodies, :charity_number
        remove_column :public_body_versions, :charity_number
    end
end

