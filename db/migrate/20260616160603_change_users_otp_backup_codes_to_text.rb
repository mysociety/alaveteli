class ChangeUsersOtpBackupCodesToText < ActiveRecord::Migration[8.0]
  # otp_backup_codes was a string column declared with `array: true`. Active
  # Record Encryption writes a single ciphertext string, which can't go into an
  # array column, so move the codes to a plain text column.
  def up
    remove_column :users, :otp_backup_codes
    add_column :users, :otp_backup_codes, :text
  end

  def down
    remove_column :users, :otp_backup_codes
    add_column :users, :otp_backup_codes, :string, array: true, default: []
  end
end
