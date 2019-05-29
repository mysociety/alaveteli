# -*- encoding : utf-8 -*-
class AddLastEventFormingInitialRequestIdToInfoRequests < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 3.2
  def change
    add_column :info_requests, :last_event_forming_initial_request_id, :integer
  end
end
