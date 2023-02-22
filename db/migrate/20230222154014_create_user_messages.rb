class CreateUserMessages < ActiveRecord::Migration[7.0]
  def change
    create_table :user_messages do |t|
      t.references :user, foreign_key: true
      t.timestamps
    end
  end
end
