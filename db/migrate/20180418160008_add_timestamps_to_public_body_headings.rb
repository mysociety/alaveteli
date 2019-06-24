# -*- encoding : utf-8 -*-
class AddTimestampsToPublicBodyHeadings <  ActiveRecord::Migration[4.2]
  def change
    add_timestamps(:public_body_headings, null: true)
  end
end
