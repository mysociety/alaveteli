# Helpers for dealing with CensorRules in the admin interface
module Admin::CensorRulesHelper
  def censor_rule_applies_to(censor_rule)
    censorable = censor_rule.censorable
    censorable ? both_links(censorable) : tag.strong('everything')
  end

  # The number of records each rule has redacted within the request, keyed by
  # rule id. Rules which have redacted nothing are absent, so callers should
  # read it with `fetch(id, 0)` or similar.
  def censor_rule_redaction_counts(censor_rules, info_request)
    return {} unless info_request

    CensorRule::Redaction.
      for_request(info_request).
      where(censor_rule: censor_rules).
      group(:censor_rule_id).
      count
  end
end
