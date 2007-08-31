class VersionPublicBody < ActiveRecord::Migration
    def self.up
        PublicBody.create_versioned_table
    end

    def self.down
        PublicBody.drop_versioned_table
    end
end
