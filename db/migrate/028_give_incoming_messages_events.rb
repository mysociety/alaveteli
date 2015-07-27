# -*- encoding : utf-8 -*-
# TODO: If this one fails with errors about described_state on save, then you need
# to temporarily modify the model for InfoRequestEvents to remove this part:
#    validates_inclusion_of :described_state, :in => [
# Or do some nice hack in here to make it happen permanently :)

class GiveIncomingMessagesEvents < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      IncomingMessage.find(:all).each do |incoming_message|
        info_request_event = InfoRequestEvent.new
        info_request_event.event_type = 'response'
        info_request_event.params = { :incoming_message_id => incoming_message.id }
        info_request_event.info_request = incoming_message.info_request
        info_request_event.created_at = incoming_message.created_at
        info_request_event.save!
      end
    end
  end

  def self.down
    InfoRequestEvent.delete_all "event_type = 'response'"
  end
end
