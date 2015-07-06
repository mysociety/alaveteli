# -*- encoding : utf-8 -*-
class CacheOnlyMarkedBodyText < ActiveRecord::Migration
    def self.up
        remove_column :incoming_messages, :cached_main_body_text
        add_column :incoming_messages, :cached_main_body_text_folded, :text
        add_column :incoming_messages, :cached_main_body_text_unfolded, :text
    end

    def self.down
        #add_column :incoming_messages, :cached_main_body_text, :text
        #remove_column :incoming_messages, :cached_main_body_text_marked
        raise "safer not to have reverse migration scripts, and we never use them"
    end
end
