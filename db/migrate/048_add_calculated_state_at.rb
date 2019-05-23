# -*- encoding : utf-8 -*-
class AddCalculatedStateAt < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 2.0
  def self.up
    # This is for use in RSS feeds
    add_column :info_request_events, :last_described_at, :datetime
  end

  def self.down
    remove_column :info_request_events, :last_described_at
  end
end
