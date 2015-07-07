# -*- encoding : utf-8 -*-
class MoveToHasTagString < ActiveRecord::Migration
    def self.up
        rename_table :public_body_tags, :has_tag_string_tags

        # we rename existing column:
        rename_column :has_tag_string_tags, :public_body_id, :model_id
        # if using has_tag_string afresh in another project, can use this:
        # add_column :has_tag_string_tags, :model_id, :integer, :null => false 
        
        # the model needs a default value, so build in stages:
        add_column :has_tag_string_tags, :model, :string
        HasTagString::HasTagStringTag.update_all "model = 'PublicBody'"
        change_column :has_tag_string_tags, :model, :string, :null => false
        # just use this for a fresh project:
        # add_column :has_tag_string_tags, :model, :string, :null => false

        add_index :has_tag_string_tags, [:model, :model_id]
    end

    def self.down
        raise "no reverse migration"
    end
end
