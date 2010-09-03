class CreateBooks < ActiveRecord::Migration
  def self.up
    create_table :books, :id => false do |t|
      t.string :name
      t.string :description
      t.timestamps
    end
    add_column :books, :guid, :integer, :primary => true
  end

  def self.down
    drop_table :books
  end
end
