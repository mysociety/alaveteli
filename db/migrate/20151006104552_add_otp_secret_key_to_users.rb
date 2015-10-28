# -*- encoding : utf-8 -*-
class AddOtpSecretKeyToUsers < ActiveRecord::Migration
  def change
    add_column :users, :otp_secret_key, :string
  end
end
