# -*- encoding : utf-8 -*-
class AddTimestampsToPublicBodyHeadings < ActiveRecord::Migration
  def change
    add_timestamps(:public_body_headings)
  end
end
