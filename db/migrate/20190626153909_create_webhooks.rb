class CreateWebhooks < ActiveRecord::Migration[5.0]
  def change
    create_table :webhooks do |t|
      t.jsonb :params
      t.datetime :notified_at

      t.timestamps
    end
  end
end
