class AddCaseSensitiveToCensorRules < ActiveRecord::Migration[8.0]
  def change
    add_column :censor_rules, :case_sensitive, :boolean,
               default: true, null: false
  end
end
