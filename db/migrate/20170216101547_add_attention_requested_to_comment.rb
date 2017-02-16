class AddAttentionRequestedToComment < ActiveRecord::Migration
  def change
    add_column :comments, :attention_requested, :boolean,
                          :null => false, :default => false
  end
end
