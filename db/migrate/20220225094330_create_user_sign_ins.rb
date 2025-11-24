class CreateUserSignIns < ActiveRecord::Migration[6.1]
  def change
    create_table :user_sign_ins do |t|
      t.references :user, foreign_key: true
      t.inet :ip
      t.timestamps
    end
  end
end
