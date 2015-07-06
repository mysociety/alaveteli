# -*- encoding : utf-8 -*-
class AddStatsDenominator < ActiveRecord::Migration
  def up
    add_column :public_bodies, :info_requests_visible_classified_count, :integer
    PublicBody.connection.execute("UPDATE public_bodies
                                     SET info_requests_visible_classified_count =
                                       (SELECT COUNT(*) FROM info_requests
                                          WHERE awaiting_description = FALSE AND
                                                prominence = 'normal' AND
                                                public_body_id = public_bodies.id);")
  end

  def down
    remove_column :public_bodies, :info_requests_visible_classified_count
  end
end
