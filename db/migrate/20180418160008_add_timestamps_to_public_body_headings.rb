# -*- encoding : utf-8 -*-
class AddTimestampsToPublicBodyHeadings < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    add_timestamps(:public_body_headings)
  end
end
