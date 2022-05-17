# Helpers for dealing with CensorRules in the admin interface
module Admin::CensorRulesHelper
  def censor_rule_applies_to(censor_rule)
    censorable = censor_rule.censorable
    censorable ? both_links(censorable) : tag.strong('everything')
  end
end
