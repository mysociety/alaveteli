class AddUniqueIndexToFoiAttachments < ActiveRecord::Migration[8.0]
  def change
    add_index :foi_attachments, [:incoming_message_id, :hexdigest], name: 'index_foi_attachments_uniqueness', unique: true
    # remove the old index as it is now redundant with the above
    remove_index :foi_attachments, :incoming_message_id, name: :index_foi_attachments_on_incoming_message_id
  end
end
