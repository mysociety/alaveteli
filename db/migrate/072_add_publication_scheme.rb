# -*- encoding : utf-8 -*-
class AddPublicationScheme < ActiveRecord::Migration
  def self.up
    add_column :public_bodies, :publication_scheme, :text, :null => false, :default => ""
    add_column :public_body_versions, :publication_scheme, :text, :null => false, :default => ""
  end

  def self.down
    remove_column :public_bodies, :publication_scheme
    remove_column :public_body_versions, :publication_scheme
  end
end
