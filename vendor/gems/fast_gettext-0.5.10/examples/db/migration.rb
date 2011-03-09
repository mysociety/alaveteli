class CreateTranslationTables < ActiveRecord::Migration
  def self.up
    create_table :translation_keys do |t|
      t.string :key, :unique=>true, :null=>false
      t.timestamps
    end
    add_index :translation_keys, :key #I am not sure if this helps....

    create_table :translation_texts do |t|
      t.text :text
      t.string :locale
      t.integer :translation_key_id, :null=>false
      t.timestamps
    end
    add_index :translation_texts, :translation_key_id
  end

  def self.down
    drop_table :translation_keys
    drop_table :translation_texts
  end
end