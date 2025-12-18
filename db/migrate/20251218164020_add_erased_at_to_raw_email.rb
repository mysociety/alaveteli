class AddErasedAtToRawEmail < ActiveRecord::Migration[8.0]
  def change
    add_column :raw_emails, :erased_at, :timestamp
  end
end
