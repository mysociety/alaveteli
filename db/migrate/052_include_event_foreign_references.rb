class IncludeEventForeignReferences < ActiveRecord::Migration[4.2] # 2.0
  def self.up
    add_column :info_request_events, :incoming_message_id, :integer
    add_column :info_request_events, :outgoing_message_id, :integer
    InfoRequestEvent.find_each do |event|
      incoming_message = event.incoming_message_via_params
      unless incoming_message.nil?
        event.incoming_message_id = incoming_message.id
      end
      outgoing_message = event.outgoing_message_via_params
      unless outgoing_message.nil?
        event.outgoing_message_id = outgoing_message.id
      end
      event.save!
    end
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      execute "ALTER TABLE info_request_events ADD CONSTRAINT fk_info_request_events_incoming_message_id FOREIGN KEY (incoming_message_id) REFERENCES incoming_messages(id)"
      execute "ALTER TABLE info_request_events ADD CONSTRAINT fk_info_request_events_outgoing_message_id FOREIGN KEY (outgoing_message_id) REFERENCES outgoing_messages(id)"
    end
  end

  def self.down
    remove_column :info_request_events, :outgoing_message_id
    remove_column :info_request_events, :incoming_message_id
  end
end
