class AddReplacedAtAndReplacedReasonToFoiAttachments < ActiveRecord::Migration[8.0]
  def change
    add_column :foi_attachments, :replaced_at, :datetime
    add_column :foi_attachments, :replaced_reason, :string
  end
end
