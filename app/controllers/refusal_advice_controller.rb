##
# Controller to store advice, from the refusal advice wizard, given to users
# after their Info Requests are marked as refused/rejected.
#
class RefusalAdviceController < ApplicationController
  before_action :authenticate

  def create
    log_event
  end

  private

  def authenticate
    authenticated_as_user?(info_request.user) if info_request
  end

  def log_event
    return unless info_request && current_user

    info_request.log_event(
      'refusal_advice',
      parsed_refusal_advice_params.merge(user_id: current_user.id).to_h
    )
  end

  def info_request
    return unless url_title_param

    @info_request ||= InfoRequest.find_by!(url_title: url_title_param)
  end

  def url_title_param
    params[:url_title]
  end

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
