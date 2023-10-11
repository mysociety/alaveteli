class RemovePublicBodyDisclosureLog < ActiveRecord::Migration[7.0]
  def change
    remove_column :public_bodies, :disclosure_log, :text
  end
end
