# -*- encoding : utf-8 -*-
require 'digest/sha1'

class AddAttentionRequestedFlagToInfoRequests < ActiveRecord::Migration
    def self.up
        add_column :info_requests, :attention_requested, :boolean, :default => false
    end
    def self.down
        remove_column :info_requests, :attention_requested
    end
end



