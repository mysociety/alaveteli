# -*- encoding : utf-8 -*-
class AddDefaultShortNameToPublicBodies < ActiveRecord::Migration

  def up
    change_column_default(:public_bodies, :short_name, '')
  end

  def down
    change_column_default(:public_bodies, :short_name, nil)
  end

end
