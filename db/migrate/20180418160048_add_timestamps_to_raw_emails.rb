# -*- encoding : utf-8 -*-
class AddTimestampsToRawEmails < ActiveRecord::Migration
  def change
    add_timestamps(:raw_emails)
  end
end
