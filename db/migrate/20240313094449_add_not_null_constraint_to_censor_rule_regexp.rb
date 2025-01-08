class AddNotNullConstraintToCensorRuleRegexp < ActiveRecord::Migration[7.0]
  def up
    change_column_default :censor_rules, :regexp, false
    CensorRule.where(regexp: nil).update_all(regexp: false)
    change_column_null :censor_rules, :regexp, false
  end

  def down
    change_column_null :censor_rules, :regexp, true
    change_column_default :censor_rules, :regexp, nil
  end
end
