class CreateCensorRuleRedactions < ActiveRecord::Migration[8.0]
  def change
    create_table :censor_rule_redactions do |t|
      t.references :censor_rule, null: false, foreign_key: { on_delete: :cascade }
      t.string :redactable_type, null: false
      t.bigint :redactable_id, null: false
      t.string :redacted_attribute, null: false

      t.timestamps
    end

    add_index :censor_rule_redactions,
              [:censor_rule_id, :redactable_type, :redactable_id, :redacted_attribute],
              unique: true,
              name: 'index_censor_rule_redactions_on_rule_and_redactable'

    add_index :censor_rule_redactions,
              [:redactable_type, :redactable_id],
              name: 'index_censor_rule_redactions_on_redactable'
  end
end
