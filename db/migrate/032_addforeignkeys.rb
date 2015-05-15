# -*- encoding : utf-8 -*-
class Addforeignkeys < ActiveRecord::Migration
    def self.up
        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            execute "ALTER TABLE incoming_messages ADD CONSTRAINT fk_incoming_messages_info_request FOREIGN KEY (info_request_id) REFERENCES info_requests(id)"

            execute "ALTER TABLE info_request_events ADD CONSTRAINT fk_info_request_events_info_request FOREIGN KEY (info_request_id) REFERENCES info_requests(id)"
            execute "ALTER TABLE info_requests ADD CONSTRAINT fk_info_requests_user FOREIGN KEY (user_id) REFERENCES users(id)"
            execute "ALTER TABLE info_requests ADD CONSTRAINT fk_info_requests_public_body FOREIGN KEY (public_body_id) REFERENCES public_bodies(id)"

            execute "ALTER TABLE outgoing_messages ADD CONSTRAINT fk_outgoing_messages_info_request FOREIGN KEY (info_request_id) REFERENCES info_requests(id)"
            execute "ALTER TABLE outgoing_messages ADD CONSTRAINT fk_incoming_message_followup_info_request FOREIGN KEY (incoming_message_followup_id) REFERENCES incoming_messages(id)"

            execute "ALTER TABLE post_redirects ADD CONSTRAINT fk_post_redirects_user FOREIGN KEY (user_id) REFERENCES users(id)"

            execute "ALTER TABLE public_body_versions ADD CONSTRAINT fk_public_body_versions_public_body FOREIGN KEY (public_body_id) REFERENCES public_bodies(id)"
        end
    end

    def self.down
        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            execute "ALTER TABLE incoming_messages DROP CONSTRAINT fk_incoming_messages_info_request"

            execute "ALTER TABLE info_request_events DROP CONSTRAINT fk_info_request_events_info_request"

            execute "ALTER TABLE info_requests DROP CONSTRAINT fk_info_requests_user"
            execute "ALTER TABLE info_requests DROP CONSTRAINT fk_info_requests_public_body"

            execute "ALTER TABLE outgoing_messages DROP CONSTRAINT fk_outgoing_messages_info_request"
            execute "ALTER TABLE outgoing_messages DROP CONSTRAINT fk_incoming_message_followup_info_request"

            execute "ALTER TABLE post_redirects DROP CONSTRAINT fk_post_redirects_user"

            execute "ALTER TABLE public_body_versions DROP CONSTRAINT fk_public_body_versions_public_body"
        end
    end
end
