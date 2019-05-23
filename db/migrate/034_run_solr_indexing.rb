# -*- encoding : utf-8 -*-
class RunSolrIndexing < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 2.0
  def self.up
    # Not using SOLR yet after all
    #PublicBody.rebuild_solr_index
  end

  def self.down
  end
end
