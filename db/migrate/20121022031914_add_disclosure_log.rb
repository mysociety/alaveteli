class AddDisclosureLog < ActiveRecord::Migration[4.2] # 2.3
  def self.up
    add_column :public_bodies, :disclosure_log, :text, :null => false, :default => ""
    add_column :public_body_versions, :disclosure_log, :text, :null => false, :default => ""
    add_column :public_body_translations, :disclosure_log, :text
  end

  def self.down
    remove_column :public_bodies, :disclosure_log
    remove_column :public_body_versions, :disclosure_log
    remove_column :public_body_translations, :disclosure_log
  end
end
