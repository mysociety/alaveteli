# -*- encoding : utf-8 -*-
class AddReceiveEmailAlertsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :receive_email_alerts, :boolean, :default => true, :null => false
  end
  def self.down
    remove_column :users, :receive_email_alerts
  end
end
