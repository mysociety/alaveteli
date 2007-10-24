class AddSentOutgoingMessage < ActiveRecord::Migration
  def self.up
      add_column :outgiong_messages, :sent_at, :datetime
  end

  def self.down
  end
end
