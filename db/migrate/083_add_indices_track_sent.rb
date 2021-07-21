class AddIndicesTrackSent < ActiveRecord::Migration[4.2] # 2.3
  def self.up
    add_index :track_things_sent_emails, :created_at
  end

  def self.down
    remove_index :track_things_sent_emails, :created_at
  end
end
