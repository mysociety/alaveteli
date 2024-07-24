class AddProminenceToHasTagStringTags < ActiveRecord::Migration[7.0]
  def change
    add_column :has_tag_string_tags, :prominence, :string, default: 'normal'
    add_column :has_tag_string_tags, :prominence_reason, :text
  end
end
