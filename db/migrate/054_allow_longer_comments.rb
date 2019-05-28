# -*- encoding : utf-8 -*-
class AllowLongerComments < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 2.0
  def self.up
    change_column :public_body_versions, :last_edit_comment, :text
  end

  def self.down
    change_column :public_body_versions, :last_edit_comment, :string
  end
end
