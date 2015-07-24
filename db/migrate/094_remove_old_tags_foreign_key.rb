# -*- encoding : utf-8 -*-
class RemoveOldTagsForeignKey < ActiveRecord::Migration
  def self.up
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      execute "ALTER TABLE has_tag_string_tags DROP CONSTRAINT fk_public_body_tags_public_body"
      execute 'DROP INDEX index_public_body_tags_on_public_body_id_and_name_and_value'
      execute 'DROP INDEX index_public_body_tags_on_name'
    end

    add_index :has_tag_string_tags, [:model, :model_id, :name, :value], :name => 'by_model_and_model_id_and_name_and_value'
    add_index :has_tag_string_tags, :name
  end

  def self.down
    raise "no reverse migration"
  end
end
