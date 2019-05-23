# -*- encoding : utf-8 -*-
class AddUrlNotes < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 2.0
  def self.up
    add_column :public_bodies, :home_page, :text, :null => false, :default => ""
    add_column :public_bodies, :notes, :text, :null => false, :default => ""
    add_column :public_body_versions, :home_page, :text
    add_column :public_body_versions, :notes, :text
  end

  def self.down
    remove_column :public_bodies, :home_page
    remove_column :public_bodies, :notes
    remove_column :public_body_versions, :home_page
    remove_column :public_body_versions, :notes
  end
end
