# -*- encoding : utf-8 -*-
class RequestHasPublicBody < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 1.2
  def self.up
    add_column :info_requests, :public_body_id, :integer
  end

  def self.down
    remove_column :info_requests, :public_body_id
  end
end
