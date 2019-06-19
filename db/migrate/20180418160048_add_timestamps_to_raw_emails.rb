# -*- encoding : utf-8 -*-
class AddTimestampsToRawEmails <  ActiveRecord::Migration[4.2]
  def change
    add_timestamps(:raw_emails, null: true)
  end
end
