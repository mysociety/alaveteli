class AddUserAgentToUserSignIns < ActiveRecord::Migration[6.1]
  def change
    add_column :user_sign_ins, :user_agent, :text
  end
end
