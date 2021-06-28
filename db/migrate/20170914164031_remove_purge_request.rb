class RemovePurgeRequest < ActiveRecord::Migration[4.2]
  def up
    drop_table :purge_requests
  end

  def down
    create_table :purge_requests do |t|
      t.column :url, :string
      t.column :created_at, :datetime, :null => false
      t.column :model, :string, :null => false
      t.column :model_id, :integer, :null => false
    end
  end
end
