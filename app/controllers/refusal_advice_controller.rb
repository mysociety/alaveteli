##
# Controller to store advice, from the refusal advice wizard, given to users
# after their Info Requests are marked as refused/rejected.
#
class RefusalAdviceController < ApplicationController
  before_action :authenticate

  def create
    log_event

    internal_redirect_to ||
      help_page_redirect ||
      external_redirect  ||
      raise(
        RefusalAdvice::Action::RedirectionError,
        "Can't redirect to #{action.target}"
      )
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

  def internal_redirect_to
    return unless info_request

    case action.target[:internal]
    when 'followup'
      redirect_to new_request_followup_path(
        request_id: info_request.id, anchor: 'followup'
      )

    when 'internal_review'
      redirect_to new_request_followup_path(
        request_id: info_request.id, internal_review: '1', anchor: 'followup'
      )

    when 'new_request'
      redirect_to new_request_to_body_path(
        url_name: info_request.public_body.url_name
      )
    end
  end

  def help_page_redirect
    help_page = action.target[:help_page]
    redirect_to help_general_path(template: help_page) if help_page
  end

  def external_redirect
    external = action.target[:external]
    redirect_to external if external
  end

  def action
    @action ||= (
      id = refusal_advice_params.fetch(:id)
      RefusalAdvice.default(info_request).actions.
        find { |action| action.id == id } ||
        raise(RefusalAdvice::UnknownAction, "Can't find action #{id}")
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
