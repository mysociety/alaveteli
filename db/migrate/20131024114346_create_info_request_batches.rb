# -*- encoding : utf-8 -*-
class CreateInfoRequestBatches < ActiveRecord::Migration
  def up
    create_table :info_request_batches do |t|
      t.column :title, :text, :null => false
      t.column :user_id, :integer, :null => false
      t.timestamps
    end
    add_column :info_requests, :info_request_batch_id, :integer, :null => true
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      execute "ALTER TABLE info_requests
                    ADD CONSTRAINT fk_info_requests_info_request_batch
                    FOREIGN KEY (info_request_batch_id) REFERENCES info_request_batches(id)"
    end
    add_index :info_requests, :info_request_batch_id
    add_index :info_request_batches, :user_id
  end

  def down
    remove_column :info_requests, :info_request_batch_id
    drop_table :info_request_batches
  end
end
