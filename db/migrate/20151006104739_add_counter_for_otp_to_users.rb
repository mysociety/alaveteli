# -*- encoding : utf-8 -*-
class AddCounterForOtpToUsers < ActiveRecord::Migration
  def change
    add_column :users, :otp_counter, :integer, :default => 1
  end
end
