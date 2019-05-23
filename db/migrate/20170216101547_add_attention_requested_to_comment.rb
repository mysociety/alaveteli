# -*- encoding : utf-8 -*-
class AddAttentionRequestedToComment < !rails5? ? ActiveRecord::Migration : ActiveRecord::Migration[4.2] # 4.0
  def change
    add_column :comments, :attention_requested, :boolean,
                          :null => false, :default => false
  end
end
