# -*- encoding : utf-8 -*-
class RemoveSessionsAgain < ActiveRecord::Migration
  def self.up
    drop_table :sessions
  end

  def self.down
    create_table :sessions do |t|
      t.string :session_id, :null => false
      t.text :data
      t.timestamps
    end

    add_index :sessions, :session_id
    add_index :sessions, :updated_at
  end
end
