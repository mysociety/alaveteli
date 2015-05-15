# -*- encoding : utf-8 -*-
class AddLawUsed < ActiveRecord::Migration
    def self.up
        add_column :info_requests, :law_used, :string, :null => false, :default => 'foi'
    end

    def self.down
        remove_column :info_requests, :law_used
    end
end
