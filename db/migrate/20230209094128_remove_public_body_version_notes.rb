class RemovePublicBodyVersionNotes < ActiveRecord::Migration[7.0]
  def change
    remove_column :public_body_versions, :notes, :text
  end
end
