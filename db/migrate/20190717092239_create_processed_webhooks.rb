class CreateProcessedWebhooks < ActiveRecord::Migration[5.0]
  def change
    create_table :processed_webhooks do |t|
      t.string :event_id

      t.timestamps
    end
  end
end
