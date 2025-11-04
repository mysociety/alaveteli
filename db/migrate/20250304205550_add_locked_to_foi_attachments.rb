class AddLockedToFoiAttachments < ActiveRecord::Migration[8.0]
  def change
    add_column :foi_attachments, :locked, :boolean, default: false
  end
end
