class CreateChunks < ActiveRecord::Migration[7.0]
  def change
    create_table :chunks do |t|
      t.references :info_request
      t.references :incoming_message
      t.references :foi_attachment
      t.text :text

      t.timestamps
    end
  end
end
