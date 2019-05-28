# -*- encoding : utf-8 -*-
class CreatePublicBodyChangeRequests <  ActiveRecord::Migration[4.2] # 3.2
  def up
    create_table :public_body_change_requests do |t|
      t.column :user_email, :string
      t.column :user_name, :string
      t.column :user_id, :integer
      t.column :public_body_name, :text
      t.column :public_body_id, :integer
      t.column :public_body_email, :string
      t.column :source_url, :text
      t.column :notes, :text
      t.column :is_open, :boolean, :null => false, :default => true
      t.timestamps :null => false
    end
  end

  def down
    drop_table :public_body_change_requests
  end
end
