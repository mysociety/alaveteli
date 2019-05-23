# -*- encoding : utf-8 -*-
class RequestUrlNames < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 2.0
  def self.up
    add_column :info_requests, :url_title, :text

    InfoRequest.find_each do |info_request|
      info_request.send(:update_url_title)
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
