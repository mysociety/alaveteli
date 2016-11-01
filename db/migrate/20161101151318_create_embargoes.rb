# -*- encoding : utf-8 -*-
class CreateEmbargoes < ActiveRecord::Migration
  def change
    create_table :embargoes do |t|
      t.belongs_to :info_request, index: true
      t.column :publish_at, :datetime, null: false
      t.timestamps
    end
  end
end
