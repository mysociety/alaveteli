# -*- encoding : utf-8 -*-
class AddStatisticsToPublicBody < ActiveRecord::Migration
  def self.up
    add_column :public_bodies, :info_requests_successful_count, :integer
    add_column :public_bodies, :info_requests_not_held_count, :integer
    add_column :public_bodies, :info_requests_overdue_count, :integer
    # We need to set the :info_requests_successful_count and
    # :info_requests_not_held_count columns, since they will
    # subsequently will be updated in after_save /
    # after_destroy. :info_requests_overdue_count, however will be set
    # from a periodically run rake task.
    PublicBody.connection.execute("UPDATE public_bodies
                                     SET info_requests_not_held_count = (SELECT COUNT(*) FROM info_requests
                                                                         WHERE described_state = 'not_held' AND
                                                                               public_body_id = public_bodies.id);")
    PublicBody.connection.execute("UPDATE public_bodies
                                     SET info_requests_successful_count = (SELECT COUNT(*) FROM info_requests
                                                                           WHERE described_state IN ('successful', 'partially_successful') AND
                                                                                 public_body_id = public_bodies.id);")
  end

  def self.down
    remove_column :public_bodies, :info_requests_successful_count
    remove_column :public_bodies, :info_requests_not_held_count
    remove_column :public_bodies, :info_requests_overdue_count
  end
end
