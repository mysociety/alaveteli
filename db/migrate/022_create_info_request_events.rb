# -*- encoding : utf-8 -*-
class CreateInfoRequestEvents < ActiveRecord::Migration
  def self.up
    create_table :info_request_events do |t|
      t.column "info_request_id", :integer
      t.column :event_type, :text
      t.column :params_yaml, :text
      t.column :created_at, :datetime
    end

    # Create the missing events for requests already sent
    InfoRequest.find(:all).each do |info_request|
      info_request_event = InfoRequestEvent.new
      info_request_event.event_type = 'sent'
      info_request_event.params = { :email => info_request.recipient_email, :outgoing_message_id => info_request.outgoing_messages[0].id }
      info_request_event.info_request = info_request
      info_request_event.created_at = info_request.outgoing_messages[0].sent_at
      info_request_event.save!
    end
  end

  def self.down
    drop_table :info_request_events
  end
end
