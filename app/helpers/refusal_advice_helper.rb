# Helpers for rendering help page refusal advice
module RefusalAdviceHelper
  def refusal_advice_actionable?(action, info_request:)
    return true unless action.target.key?(:internal)
    current_user && current_user == info_request&.user
  end
end
