##
# Controller to store advice, from the refusal advice wizard, given to users
# after their Info Requests are marked as refused/rejected.
#
class RefusalAdviceController < ApplicationController
  def create
    @params = parsed_refusal_advice_params # TODO: move into log event method
  end

  private

  def refusal_advice_params
    params.require('refusal_advice').permit(:id, questions: {}, actions: {})
  end

  def parsed_refusal_advice_params
    refusal_advice_params.merge(
      actions: refusal_advice_params.fetch(:actions).
        each_pair do |_, suggestions|
          suggestions.transform_values! { |v| v == 'true' }
        end
    )
  end
end
