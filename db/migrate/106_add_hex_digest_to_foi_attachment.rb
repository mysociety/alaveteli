# -*- encoding : utf-8 -*-
class AddHexDigestToFoiAttachment < ActiveRecord::Migration
  def self.up
    add_column :foi_attachments, :hexdigest, :string, :limit => 32
  end

  def self.down
    remove_column :foi_attachments, :hexdigest
  end
end
