# -*- encoding : utf-8 -*-
class IndicesForAnnotations < ActiveRecord::Migration
    def self.up
        add_index :info_request_events, :created_at
        add_index :info_request_events, :info_request_id
    end

    def self.down
        remove_index :info_request_events, :created_at
        remove_index :info_request_events, :info_request_id
    end
end
