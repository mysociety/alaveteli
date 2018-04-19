# -*- encoding : utf-8 -*-
class AddTimestampsToPublicBodyCategoryLinks < ActiveRecord::Migration
  def change
    add_timestamps(:public_body_category_links)
  end
end
