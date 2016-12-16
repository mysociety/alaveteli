# -*- encoding : utf-8 -*-
class AddLastEventFormingInitialRequestIdToInfoRequests < ActiveRecord::Migration
  def change
    add_column :info_requests, :last_event_forming_initial_request_id, :integer
  end
end
