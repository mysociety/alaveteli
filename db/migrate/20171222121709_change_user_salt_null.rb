class ChangeUserSaltNull < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    change_column_null :users, :salt, true
  end
end
