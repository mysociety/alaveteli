class StopNewResponses < ActiveRecord::Migration
    def self.up
        add_column :info_requests, :stop_new_responses, :boolean, :default => false, :null => false
    end

    def self.down
        remove :info_requests, :stop_new_responses
    end
end
