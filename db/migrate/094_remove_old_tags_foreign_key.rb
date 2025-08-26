class RemoveOldTagsForeignKey < ActiveRecord::Migration[4.2] # 2.3
  def self.up
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      execute "ALTER TABLE has_tag_string_tags DROP CONSTRAINT fk_public_body_tags_public_body"
    end

    add_index :has_tag_string_tags, [:model, :model_id, :name, :value], :name => 'by_model_and_model_id_and_name_and_value'
  end

  def self.down
    raise "no reverse migration"
  end
end
