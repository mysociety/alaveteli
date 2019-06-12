# -*- encoding : utf-8 -*-
class CreateEmbargoes < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 3.2
  def change
    create_table :embargoes do |t|
      t.belongs_to :info_request, index: true
      t.column :publish_at, :datetime, null: false
      t.timestamps null: false
    end
  end
end
