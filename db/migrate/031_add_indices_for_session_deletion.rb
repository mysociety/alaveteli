# -*- encoding : utf-8 -*-
class AddIndicesForSessionDeletion < ActiveRecord::Migration
    def self.up
        add_index :post_redirects, :updated_at
    end

    def self.down
        remove_index :post_redirects, :updated_at
    end
end
