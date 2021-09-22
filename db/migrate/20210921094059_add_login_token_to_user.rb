class AddLoginTokenToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :login_token, :string
  end
end
