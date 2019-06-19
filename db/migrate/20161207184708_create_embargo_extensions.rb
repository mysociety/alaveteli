# -*- encoding : utf-8 -*-
class CreateEmbargoExtensions <  ActiveRecord::Migration[4.2] # 3.2
  def change
    create_table :embargo_extensions do |t|
      t.integer :embargo_id
      t.string :extension_duration

      t.timestamps null: false
    end
  end
end
