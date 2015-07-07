# -*- encoding : utf-8 -*-
class CreateWidgetVotes < ActiveRecord::Migration
  def change
    create_table :widget_votes do |t|
      t.string :cookie
      t.belongs_to :info_request, :null => false

      t.timestamps
    end
    add_index :widget_votes, :info_request_id
  end
end
