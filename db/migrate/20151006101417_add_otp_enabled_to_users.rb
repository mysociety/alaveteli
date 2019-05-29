# -*- encoding : utf-8 -*-
class AddOtpEnabledToUsers < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 3.2
  def change
    add_column :users, :otp_enabled, :boolean, :default => false, :null => false
  end
end
