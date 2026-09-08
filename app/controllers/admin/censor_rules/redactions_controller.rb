# Show which child records of the InfoRequest have had content removed by the
# CensorRule
class Admin::CensorRules::RedactionsController < AdminController
  before_action :set_info_request
  before_action :set_censor_rule

  def index
    @redactions =
      @censor_rule.
      redactions.
      for_request(@info_request).
      includes(:redactable).
      sort_by { |r| r.redactable.created_at }
  end

  private

  def set_info_request
    @info_request = InfoRequest.find(params[:request_id])
  end

  def set_censor_rule
    @censor_rule = CensorRule.find(params[:censor_rule_id])
  end
end
