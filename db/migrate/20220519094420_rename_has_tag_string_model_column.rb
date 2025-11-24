class RenameHasTagStringModelColumn < ActiveRecord::Migration[6.1]
  def change
    rename_column :has_tag_string_tags, :model, :model_type
  end
end
