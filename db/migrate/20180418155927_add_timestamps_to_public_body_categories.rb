# -*- encoding : utf-8 -*-
class AddTimestampsToPublicBodyCategories <  ActiveRecord::Migration[4.2]
  def change
    add_timestamps(:public_body_categories, null: true)
  end
end
