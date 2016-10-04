class CreateRolloutKeyValueStores < ActiveRecord::Migration
  def change
    create_table :rollout_key_value_stores do |t|
      t.string :key
      t.string :value

      t.timestamps
    end
    add_index :rollout_key_value_stores, :key
  end
end
