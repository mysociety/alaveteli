class CreateInfoRequests < ActiveRecord::Migration[4.2] # 1.2
  def self.up
    create_table :info_requests do |t|
      t.column :title,   :text
      t.column :user_id, :integer
    end
  end

  def self.down
    drop_table :info_requests
  end
end
