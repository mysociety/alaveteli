class CreateUserEmailHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :user_email_histories do |t|
      t.references :user, null: false, foreign_key: true
      t.string :old_email, null: false
      t.string :new_email, null: false
      t.datetime :changed_at, null: false

      t.timestamps
    end
  end
end
