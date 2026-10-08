class AddErasedAtToCensorRules < ActiveRecord::Migration[8.0]
  def change
    add_column :censor_rules, :erased_at, :datetime
  end
end
