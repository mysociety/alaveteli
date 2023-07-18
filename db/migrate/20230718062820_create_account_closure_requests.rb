class CreateAccountClosureRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :account_closure_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
