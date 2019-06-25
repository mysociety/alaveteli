# -*- encoding : utf-8 -*-
class AddTimestampsToFoiAttachments < ActiveRecord::Migration[4.2]
  def change
    add_timestamps(:foi_attachments, null: true)
  end
end
