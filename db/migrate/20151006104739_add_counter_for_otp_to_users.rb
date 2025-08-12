class AddCounterForOtpToUsers < ActiveRecord::Migration[4.2] # 3.2
  def change
    add_column :users, :otp_counter, :integer, :default => 1
  end
end
