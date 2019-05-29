# -*- encoding : utf-8 -*-
class IndexRequestsWithSolr < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 2.0
  def self.up
    add_column :info_requests, :solr_up_to_date, :boolean, :default => false, :null => false
    add_index :info_requests, :solr_up_to_date
  end

  def self.down
    remove_index :info_requests, :solr_up_to_date
    remove_column :info_requests, :solr_up_to_date
  end
end
