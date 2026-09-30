# List the CensorRules that apply to a User's requests, along with the records
# within those requests that each rule has redacted
class Admin::Users::CensorRulesController < AdminController
  layout 'admin/users'

  before_action :set_admin_user

  def index
    @title = "Censor rules for #{@admin_user.name}"

    info_requests = @admin_user.info_requests
    if cannot? :admin, AlaveteliPro::Embargo
      info_requests = info_requests.not_embargoed
    end

    @censor_rules =
      CensorRule.
      applicable_to_requests(info_requests).
      or(CensorRule.where(censorable: @admin_user)).
      includes(:censorable).
      order(:censorable_type, :censorable_id, :id)

    @redactions = redactions(info_requests)
  end

  private

  def set_admin_user
    # Don't use @user as that is any logged in user
    @admin_user = User.find(params[:user_id])
  end

  # Redactions within the requests, grouped by CensorRule id
  def redactions(info_requests)
    return {} unless feature_enabled?(:redaction_tracking)

    CensorRule::Redaction.
      for_requests(info_requests).
      where(censor_rule: @censor_rules.reorder(nil)).
      includes(:redactable).
      sort_by { |r| r.redactable.created_at }.
      group_by(&:censor_rule_id)
  end
end
