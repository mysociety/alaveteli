# -*- encoding : utf-8 -*-
class AddExternalFieldsToInfoRequests < ActiveRecord::Migration
  def self.up
    change_column_null :info_requests, :user_id, true
    add_column :info_requests, :external_user_name, :string, :null => true
    add_column :info_requests, :external_url, :string, :null => true

    # NB This is corrected in 20120822145640
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      execute "ALTER TABLE info_requests ADD CONSTRAINT info_requests_external_ck CHECK ( (user_id is null) = (external_url is not null) and (external_user_name is not null or external_url is null) )"
    end
  end

  def self.down
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      execute "ALTER TABLE info_requests DROP CONSTRAINT info_requests_external_ck"
    end

    remove_column :info_requests, :external_url
    remove_column :info_requests, :external_user_name

    change_column_null :info_requests, :user_id, false
  end
end
