class AddStyleToNotes < ActiveRecord::Migration[7.0]
  def change
    add_column :notes, :style, :string, default: 'original', null: false
  end
end
