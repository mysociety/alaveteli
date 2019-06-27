# -*- encoding : utf-8 -*-
class AddUpdatedAtToHasTagStringTags < ActiveRecord::Migration[4.2]
  def up
    add_column :has_tag_string_tags, :updated_at, :datetime
  end

  def down
    remove_column :has_tag_string_tags, :updated_at
  end
end
