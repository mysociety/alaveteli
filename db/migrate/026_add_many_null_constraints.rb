# -*- encoding : utf-8 -*-
class AddManyNullConstraints < ActiveRecord::Migration
  def self.up
        change_column :users, :email, :string, :null => false
        change_column :users, :name, :string, :null => false
        change_column :users, :hashed_password, :string, :null => false
        change_column :users, :salt, :string, :null => false
        change_column :users, :created_at, :datetime, :null => false
        change_column :users, :updated_at, :datetime, :null => false
        change_column :users, :email_confirmed, :boolean, :null => false, :default =>false
        
        change_column :public_bodies, :name, :text, :null => false
        change_column :public_bodies, :short_name, :text, :null => false
        change_column :public_bodies, :request_email, :text, :null => false
        change_column :public_bodies, :version, :integer, :null => false
        change_column :public_bodies, :last_edit_editor, :string, :null => false
        change_column :public_bodies, :last_edit_comment, :text, :null => false
        change_column :public_bodies, :created_at, :datetime, :null => false
        change_column :public_bodies, :updated_at, :datetime, :null => false

        change_column :post_redirects, :token, :text, :null => false
        change_column :post_redirects, :uri, :text, :null => false
        change_column :post_redirects, :created_at, :datetime, :null => false
        change_column :post_redirects, :updated_at, :datetime, :null => false
        change_column :post_redirects, :email_token, :text, :null => false

        change_column :outgoing_messages, :info_request_id, :integer, :null => false
        change_column :outgoing_messages, :body, :text, :null => false
        change_column :outgoing_messages, :status, :string, :null => false
        change_column :outgoing_messages, :message_type, :string, :null => false
        change_column :outgoing_messages, :created_at, :datetime, :null => false
        change_column :outgoing_messages, :updated_at, :datetime, :null => false

        change_column :info_requests, :title, :text, :null => false
        change_column :info_requests, :user_id, :integer, :null => false
        change_column :info_requests, :public_body_id, :integer, :null => false
        change_column :info_requests, :created_at, :datetime, :null => false
        change_column :info_requests, :updated_at, :datetime, :null => false

        change_column :info_request_events, :info_request_id, :integer, :null => false
        change_column :info_request_events, :event_type, :text, :null => false
        change_column :info_request_events, :params_yaml, :text, :null => false
        change_column :info_request_events, :created_at, :datetime, :null => false

        change_column :incoming_messages, :info_request_id, :integer, :null => false
        change_column :incoming_messages, :raw_data, :text, :null => false
        change_column :incoming_messages, :created_at, :datetime, :null => false
        change_column :incoming_messages, :updated_at, :datetime, :null => false
        change_column :incoming_messages, :user_classified, :boolean, :null => false, :default => false
        change_column :incoming_messages, :is_bounce, :boolean, :null => false, :default => false

  end

  def self.down
        change_column :users, :email, :string, :null => true
        change_column :users, :name, :string, :null => true
        change_column :users, :hashed_password, :string, :null => true
        change_column :users, :salt, :string, :null => true
        change_column :users, :created_at, :datetime, :null => true
        change_column :users, :updated_at, :datetime, :null => true
        change_column :users, :email_confirmed, :boolean, :null => true, :default =>false

        change_column :public_bodies, :name, :text, :null => true
        change_column :public_bodies, :short_name, :text, :null => true
        change_column :public_bodies, :request_email, :text, :null => true
        change_column :public_bodies, :version, :integer, :null => true
        change_column :public_bodies, :last_edit_editor, :string, :null => true
        change_column :public_bodies, :last_edit_comment, :string, :null => true
        change_column :public_bodies, :created_at, :datetime, :null => true
        change_column :public_bodies, :updated_at, :datetime, :null => true

        change_column :post_redirects, :token, :text, :null => true
        change_column :post_redirects, :uri, :text, :null => true
        change_column :post_redirects, :created_at, :datetime, :null => true
        change_column :post_redirects, :updated_at, :datetime, :null => true
        change_column :post_redirects, :email_token, :text, :null => true

        change_column :outgoing_messages, :info_request_id, :integer, :null => true
        change_column :outgoing_messages, :body, :text, :null => true
        change_column :outgoing_messages, :status, :string, :null => true
        change_column :outgoing_messages, :message_type, :string, :null => true
        change_column :outgoing_messages, :created_at, :datetime, :null => true
        change_column :outgoing_messages, :updated_at, :datetime, :null => true

        change_column :info_requests, :title, :text, :null => true
        change_column :info_requests, :user_id, :integer, :null => true
        change_column :info_requests, :public_body_id, :integer, :null => true
        change_column :info_requests, :created_at, :datetime, :null => true
        change_column :info_requests, :updated_at, :datetime, :null => true

        change_column :info_request_events, :info_request_id, :integer, :null => true
        change_column :info_request_events, :event_type, :text, :null => true
        change_column :info_request_events, :params_yaml, :text, :null => true
        change_column :info_request_events, :created_at, :datetime, :null => true

        change_column :incoming_messages, :info_request_id, :integer, :null => true
        change_column :incoming_messages, :raw_data, :text, :null => true
        change_column :incoming_messages, :created_at, :datetime, :null => true
        change_column :incoming_messages, :updated_at, :datetime, :null => true
        change_column :incoming_messages, :user_classified, :boolean, :null => true, :default => false
        change_column :incoming_messages, :is_bounce, :boolean, :null => true, :default => false

   end
end
