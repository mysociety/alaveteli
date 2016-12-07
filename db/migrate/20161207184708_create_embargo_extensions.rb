class CreateEmbargoExtensions < ActiveRecord::Migration
  def change
    create_table :embargo_extensions do |t|
      t.integer :embargo_id
      t.string :extension_duration

      t.timestamps
    end
  end
end
