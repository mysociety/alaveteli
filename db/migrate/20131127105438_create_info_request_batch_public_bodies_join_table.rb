# -*- encoding : utf-8 -*-
class CreateInfoRequestBatchPublicBodiesJoinTable < ActiveRecord::Migration
  def change
    create_table :info_request_batches_public_bodies, :id => false do |t|
      t.integer :info_request_batch_id
      t.integer :public_body_id
    end
  end
end
