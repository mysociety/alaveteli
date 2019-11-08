class BigintRawEmails < ActiveRecord::Migration[6.1]
  def up
    change_column :raw_emails, :id, :bigint
  end

  def down
    change_column :raw_emails, :id, :integer
  end
end
