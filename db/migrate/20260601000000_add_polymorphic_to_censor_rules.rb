class AddPolymorphicToCensorRules < ActiveRecord::Migration[8.0]
  def up
    add_reference :censor_rules, :censorable, polymorphic: true

    execute <<~SQL
      UPDATE censor_rules
      SET censorable_type = 'InfoRequest', censorable_id = info_request_id
      WHERE info_request_id IS NOT NULL
    SQL

    execute <<~SQL
      UPDATE censor_rules
      SET censorable_type = 'User', censorable_id = user_id
      WHERE user_id IS NOT NULL
    SQL

    execute <<~SQL
      UPDATE censor_rules
      SET censorable_type = 'PublicBody', censorable_id = public_body_id
      WHERE public_body_id IS NOT NULL
    SQL

    remove_column :censor_rules, :info_request_id
    remove_column :censor_rules, :user_id
    remove_column :censor_rules, :public_body_id
  end

  def down
    add_column :censor_rules, :info_request_id, :integer
    add_column :censor_rules, :user_id, :integer
    add_column :censor_rules, :public_body_id, :integer

    add_foreign_key :censor_rules, :info_requests
    add_foreign_key :censor_rules, :public_bodies
    add_foreign_key :censor_rules, :users

    add_index :censor_rules, :info_request_id
    add_index :censor_rules, :user_id
    add_index :censor_rules, :public_body_id

    execute <<~SQL
      UPDATE censor_rules
      SET info_request_id = censorable_id
      WHERE censorable_type = 'InfoRequest'
    SQL

    execute <<~SQL
      UPDATE censor_rules
      SET user_id = censorable_id
      WHERE censorable_type = 'User'
    SQL

    execute <<~SQL
      UPDATE censor_rules
      SET public_body_id = censorable_id
      WHERE censorable_type = 'PublicBody'
    SQL

    remove_reference :censor_rules, :censorable, polymorphic: true
  end
end
