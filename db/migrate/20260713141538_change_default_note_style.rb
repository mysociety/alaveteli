class ChangeDefaultNoteStyle < ActiveRecord::Migration[8.0]
  def change
    change_column_default :notes, :style, from: 'original', to: 'blue'
  end
end
