class AddMaskedAtToFoiAttachments < ActiveRecord::Migration[7.0]
  def change
    add_column :foi_attachments, :masked_at, :datetime
  end
end
