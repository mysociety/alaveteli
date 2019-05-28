# -*- encoding : utf-8 -*-
class CreateWidgetVotes <  ActiveRecord::Migration[4.2] # 3.2
  def change
    create_table :widget_votes do |t|
      t.string :cookie
      t.belongs_to :info_request, :null => false

      t.timestamps :null => false
    end
    add_index :widget_votes, :info_request_id
  end
end
