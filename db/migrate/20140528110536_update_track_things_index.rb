# -*- encoding : utf-8 -*-
class UpdateTrackThingsIndex < ActiveRecord::Migration

  def up
      if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
          execute "ALTER TABLE track_things_sent_emails DROP CONSTRAINT fk_track_request_public_body"
          execute "ALTER TABLE track_things_sent_emails ADD CONSTRAINT fk_track_request_public_body FOREIGN KEY (public_body_id) REFERENCES public_bodies(id)"
      end
  end

  def down
      if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
          execute "ALTER TABLE track_things_sent_emails DROP CONSTRAINT fk_track_request_public_body"
          execute "ALTER TABLE track_things_sent_emails ADD CONSTRAINT fk_track_request_public_body FOREIGN KEY (user_id) REFERENCES users(id)"
      end
  end

end
