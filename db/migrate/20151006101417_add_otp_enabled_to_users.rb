# -*- encoding : utf-8 -*-
class AddOtpEnabledToUsers < ActiveRecord::Migration
  def change
    add_column :users, :otp_enabled, :boolean, :default => false, :null => false
  end
end
