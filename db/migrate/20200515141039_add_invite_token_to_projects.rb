class AddInviteTokenToProjects < ActiveRecord::Migration[5.1]
  def change
    add_column :projects, :invite_token, :string
  end
end
