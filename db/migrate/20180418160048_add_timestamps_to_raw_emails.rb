# -*- encoding : utf-8 -*-
class AddTimestampsToRawEmails < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    add_timestamps(:raw_emails, null: true)
  end
end
