# -*- encoding : utf-8 -*-
class CreateNotifications < ActiveRecord::Migration
  def change
    create_table :notifications do |t|
      t.references :info_request_event, null: false, index: true
      t.references :user, null: false, index: true
      t.integer :frequency, default: 0, null: false, index: true
      t.timestamp :seen_at, index: true
      t.timestamp :send_after, null: false, index: true

      t.timestamps null: false
    end
  end
end
