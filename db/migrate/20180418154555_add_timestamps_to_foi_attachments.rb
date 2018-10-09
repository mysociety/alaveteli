# -*- encoding : utf-8 -*-
class AddTimestampsToFoiAttachments < ActiveRecord::Migration
  def change
    add_timestamps(:foi_attachments)
  end
end
