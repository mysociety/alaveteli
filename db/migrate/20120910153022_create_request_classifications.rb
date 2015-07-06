# -*- encoding : utf-8 -*-
class CreateRequestClassifications < ActiveRecord::Migration
  def self.up
    create_table :request_classifications do |t|
      t.integer :user_id
      t.integer :info_request_event_id
      t.timestamps
    end
    add_index :request_classifications, :user_id
  end

  def self.down
    drop_table :request_classifications
  end
end
