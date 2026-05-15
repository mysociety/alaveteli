class AddIgnoreDiacriticsToCensorRules < ActiveRecord::Migration[8.0]
  def change
    add_column :censor_rules, :ignore_diacritics, :boolean,
               default: false, null: false
  end
end
