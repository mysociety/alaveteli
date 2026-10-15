# List the CensorRules that apply to a User's requests, along with the records
# within those requests that each rule has redacted
class Admin::Users::CensorRulesController < AdminController
  layout 'admin/users'

  before_action :set_admin_user, :set_info_requests, :set_censor_rules

  def index
    @title = "Censor rules for #{@admin_user.name}"
    @redactions = redactions
  end

  # Fix the redactions of the selected rules in place, then erase the rules so
  # that we no longer hold the content they matched
  def make_permanent
    rules = @censor_rules.erasable.where(id: params[:censor_rule_ids]).to_a

    if rules.empty?
      flash[:error] = 'No censor rules selected.'
      return redirect_to admin_user_censor_rules_path(@admin_user)
    end

    if CensorRule.make_permanent_and_erase(rules, editor: admin_current_user)
      flash[:notice] = "Made #{rules.size} censor rule(s) permanent."
    else
      flash[:error] = 'Some redactions could not be made permanent. No ' \
                      'censor rules were erased.'
    end

    redirect_to admin_user_censor_rules_path(@admin_user)
  end

  private

  def set_admin_user
    # Don't use @user as that is any logged in user
    @admin_user = User.find(params[:user_id])
  end

  def set_info_requests
    @info_requests = @admin_user.info_requests
    return if can? :admin, AlaveteliPro::Embargo

    @info_requests = @info_requests.not_embargoed
  end

  def set_censor_rules
    @censor_rules =
      CensorRule.
      applicable_to_requests(@info_requests).
      or(CensorRule.where(censorable: @admin_user)).
      includes(:censorable).
      order(:censorable_type, :censorable_id, :id)
  end

  # Redactions within the requests, grouped by CensorRule id
  def redactions
    return {} unless feature_enabled?(:redaction_tracking)

    CensorRule::Redaction.
      for_requests(@info_requests).
      where(censor_rule: @censor_rules.reorder(nil)).
      includes(:redactable).
      sort_by { |r| r.redactable.created_at }.
      group_by(&:censor_rule_id)
  end
end
