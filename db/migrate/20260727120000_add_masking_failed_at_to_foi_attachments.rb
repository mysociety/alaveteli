class AddMaskingFailedAtToFoiAttachments < ActiveRecord::Migration[8.0]
  def change
    add_column :foi_attachments, :masking_failed_at, :datetime
  end
end
