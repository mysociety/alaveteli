class AddTotpFieldsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :otp_last_used_at, :integer
    add_column :users, :otp_backup_codes, :string, array: true, default: []
    add_column :users, :otp_enabled_at, :datetime
    add_column :users, :otp_backup_codes_generated_at, :datetime

    change_column_default :users, :otp_counter, from: 1, to: nil
  end
end
