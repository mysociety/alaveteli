class AddCachedTextToFoiAttachments < ActiveRecord::Migration[7.0]
  def change
    add_column :foi_attachments, :cached_text, :text
  end
end
