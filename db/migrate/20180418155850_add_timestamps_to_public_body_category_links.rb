# -*- encoding : utf-8 -*-
class AddTimestampsToPublicBodyCategoryLinks < ActiveRecord::Migration[4.2]
  def change
    add_timestamps(:public_body_category_links, null: true)
  end
end
