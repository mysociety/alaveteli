class RunSolrIndexing < ActiveRecord::Migration
    def self.up
        PublicBody.rebuild_solr_index
    end

    def self.down
    end
end
