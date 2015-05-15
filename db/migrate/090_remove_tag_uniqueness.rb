# -*- encoding : utf-8 -*-
class RemoveTagUniqueness < ActiveRecord::Migration
    def self.up
        # MySQL cannot index text blobs like this
        # TODO: perhaps should change :name/:value to be a :string
        if ActiveRecord::Base.connection.adapter_name != "MySQL"
            remove_index :public_body_tags, [:public_body_id, :name]
            # allow the key to repeat, but not the value also
            add_index :public_body_tags, [:public_body_id, :name, :value], :unique => true
        end
    end

    def self.down
        raise "No reverse migration"
    end
end

