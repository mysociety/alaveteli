class ChangeUserSaltNull < ActiveRecord::Migration[4.2]
  def change
    change_column_null :users, :salt, true
  end
end
