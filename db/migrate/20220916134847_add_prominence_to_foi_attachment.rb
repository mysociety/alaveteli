class AddProminenceToFoiAttachment < ActiveRecord::Migration[6.1]
  def change
    add_column :foi_attachments, :prominence, :string, default: 'normal'
    add_column :foi_attachments, :prominence_reason, :text
  end
end
