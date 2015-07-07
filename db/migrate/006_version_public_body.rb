# -*- encoding : utf-8 -*-
class VersionPublicBody < ActiveRecord::Migration
    def self.up
        PublicBody.create_versioned_table

        add_timestamps(:public_body_versions)
    end

    def self.down
        PublicBody.drop_versioned_table
    end
end
