class RemoveOldTagsForeignKey < ActiveRecord::Migration
    def self.up
        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            execute "ALTER TABLE has_tag_string_tags DROP CONSTRAINT fk_public_body_tags_public_body"
        end

        remove_index :public_body_tags, [:public_body_id, :name, :value]
        remove_index :public_body_tags, :name

        add_index :has_tag_string_tags, [:model, :model_id, :name, :value]
        add_index :has_tag_string_tags, :name
    end

    def self.down
        raise "no reverse migration"
    end
end
