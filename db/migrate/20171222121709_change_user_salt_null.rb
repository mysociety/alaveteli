class ChangeUserSaltNull < ActiveRecord::Migration
  def change
    change_column_null :users, :salt, true
  end
end
