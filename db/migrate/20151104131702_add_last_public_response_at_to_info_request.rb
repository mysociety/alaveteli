# -*- encoding : utf-8 -*-
class AddLastPublicResponseAtToInfoRequest < ActiveRecord::Migration
  def up
    add_column :info_requests, :last_public_response_at, :datetime, :null => true

    InfoRequest.connection.
      execute("UPDATE info_requests
                 SET last_public_response_at = (SELECT MAX(info_request_events.created_at)
                                             FROM info_request_events, incoming_messages
                                             WHERE incoming_messages.id = info_request_events.incoming_message_id AND
                                             prominence = 'normal' AND
                                             event_type = 'response' AND
                                             info_request_events.info_request_id = info_requests.id);")
  end

  def down
    remove_column :info_requests, :last_public_response_at
  end
end
