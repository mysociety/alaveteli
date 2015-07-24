# -*- encoding : utf-8 -*-
class SentAreWaitingResponse < ActiveRecord::Migration
  def self.up
    InfoRequestEvent.update_all "described_state = 'waiting_response', calculated_state = 'waiting_response', last_described_at = created_at where event_type = 'sent'"
  end

  def self.down
  end
end
