# Helpers for rendering help page refusal advice
module RefusalAdviceHelper
  def refusal_advice_actionable?(action, info_request:)
    return true unless action.target.key?(:internal)
    current_user && current_user == info_request&.user
  end

  def refusal_advice_form_data(info_request)
    return {} unless info_request

    { refusals: info_request.latest_refusals.map(&:to_param) }
  end
end
