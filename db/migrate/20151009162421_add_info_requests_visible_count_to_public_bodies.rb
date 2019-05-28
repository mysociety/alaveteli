# -*- encoding : utf-8 -*-
class AddInfoRequestsVisibleCountToPublicBodies < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 3.2
  def up
    add_column :public_bodies, :info_requests_visible_count, :integer, :null => false, :default => 0

    PublicBody.connection.execute("UPDATE public_bodies
                                   SET info_requests_visible_count = (SELECT COUNT(*) FROM info_requests
                                                              WHERE  prominence = 'normal' AND
                                                                     public_body_id = public_bodies.id);")
  end

  def down
    remove_column :public_bodies, :info_requests_visible_count
  end
end
