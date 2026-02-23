class AddErasedAtToFoiAttachments < ActiveRecord::Migration[8.0]
  def change
    add_column :foi_attachments, :erased_at, :datetime
  end
end
