# -*- encoding : utf-8 -*-
class CreateRequestClassifications < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 2.3
  def self.up
    create_table :request_classifications do |t|
      t.integer :user_id
      t.integer :info_request_event_id
      t.timestamps :null => false
    end
    add_index :request_classifications, :user_id
  end

  def self.down
    drop_table :request_classifications
  end
end
