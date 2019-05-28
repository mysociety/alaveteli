# -*- encoding : utf-8 -*-
require 'digest/sha1'

class AddAttentionRequestedFlagToInfoRequests < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 2.3
  def self.up
    add_column :info_requests, :attention_requested, :boolean, :default => false
  end
  def self.down
    remove_column :info_requests, :attention_requested
  end
end
