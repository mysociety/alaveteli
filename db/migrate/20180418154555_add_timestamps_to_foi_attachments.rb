# -*- encoding : utf-8 -*-
class AddTimestampsToFoiAttachments < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2]
  def change
    add_timestamps(:foi_attachments)
  end
end
