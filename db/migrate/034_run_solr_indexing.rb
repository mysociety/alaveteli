# -*- encoding : utf-8 -*-
class RunSolrIndexing < ActiveRecord::Migration
  def self.up
    # Not using SOLR yet after all
    #PublicBody.rebuild_solr_index
  end

  def self.down
  end
end
