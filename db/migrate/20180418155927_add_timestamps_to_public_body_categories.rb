# -*- encoding : utf-8 -*-
class AddTimestampsToPublicBodyCategories < ActiveRecord::Migration
  def change
    add_timestamps(:public_body_categories)
  end
end
