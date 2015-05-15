# -*- encoding : utf-8 -*-
class RequestUrlNames < ActiveRecord::Migration
    def self.up
        add_column :info_requests, :url_title, :text

        InfoRequest.find(:all).each do |info_request|
            info_request.update_url_title
            info_request.save!
        end
        # MySQL cannot index text blobs like this
        if ActiveRecord::Base.connection.adapter_name != "MySQL"
            add_index :info_requests, :url_title, :unique => true
        end
        change_column :info_requests, :url_title, :text, :null => false
    end

    def self.down
        remove_column :info_requests, :url_title
    end
end

