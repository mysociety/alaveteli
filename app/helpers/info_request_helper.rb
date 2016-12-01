# -*- encoding : utf-8 -*-
module InfoRequestHelper
  include ConfigHelper
  include DateTimeHelper
  include LinkToHelper

  def status_text(status, opts = {})
    method = "status_text_#{ status }"
    if respond_to?(method, true)
      send(method, opts)
    else
      custom_state_description(status)
    end
  end

  private

  def status_text_waiting_response(opts = {})
    info_request = opts.fetch(:info_request)

    str = _('Currently <strong>waiting for a response</strong> from ' \
            '{{public_body_link}}, they must respond promptly and',
            :public_body_link => public_body_link(info_request.public_body))
    str += ' '
    str += _('normally')
    str += ' '
    str += _('no later than')
    str += ' '
    str += content_tag(:strong,
                       simple_date(info_request.date_response_required_by))
    str += ' '
    str += "("
    str += link_to _("details"), "/help/requesting#quickly_response"
    str += ")."
  end

  def status_text_waiting_response_overdue(opts = {})
    info_request = opts.fetch(:info_request)

    str = _('Response to this request is <strong>delayed</strong>.')
    str += ' '
    str += _('By law, {{public_body_link}} should normally have responded ' \
             '<strong>promptly</strong> and',
             :public_body_link => public_body_link(info_request.public_body))
    str += ' '
    str += _('by')
    str += ' '
    str += content_tag(:strong,
                       simple_date(info_request.date_response_required_by))
    str += ' '
    str += "("
    str += link_to _('details'),
                   help_requesting_path(:anchor => 'quickly_response')
    str += ")"
  end

  def status_text_waiting_response_very_overdue(opts = {})
    info_request = opts.fetch(:info_request)

    str = _('Response to this request is <strong>long overdue</strong>.')
    str += ' '
    str += _('By law, under all circumstances, {{public_body_link}} should ' \
            'have responded by now',
            :public_body_link => public_body_link(info_request.public_body))
    str += ' '
    str += "("
    str += link_to _('details'),
                   help_requesting_path(:anchor => 'quickly_response')
    str += ")."

    unless info_request.is_external?
      str += ' '
      str += _('You can <strong>complain</strong> by')
      str += ' '
      str += link_to _("requesting an internal review"),
                    new_request_followup_path(:request_id => info_request.id) +
                    "?internal_review=1#followup"
      str += '.'
    end

    str
  end

  def status_text_not_held(opts = {})
    info_request = opts.fetch(:info_request)

    _('{{authority_name}} <strong>did not have</strong> the information ' \
      'requested.',
      :authority_name => public_body_link(info_request.public_body))
  end

  def status_text_rejected(opts = {})
    info_request = opts.fetch(:info_request)

    _('The request was <strong>refused</strong> by {{authority_name}}.',
      :authority_name => public_body_link(info_request.public_body))
  end

  def status_text_successful(opts = {})
    _('The request was <strong>successful</strong>.')
  end

  def status_text_partially_successful(opts = {})
    _('The request was <strong>partially successful</strong>.')
  end

  def status_text_waiting_clarification(opts = {})
    info_request = opts.fetch(:info_request)
    is_owning_user = opts.fetch(:is_owning_user)

    str = ''.html_safe

    if is_owning_user && !info_request.is_external?
      str += _('{{authority_name}} is <strong>waiting for your clarification' \
               '</strong>.',
               :authority_name => info_request.public_body.name)
      str += ' '
      str += _('Please')
      str += ' '
      str += link_to _("send a follow up message"),
                     respond_to_last_path(info_request, :anchor => 'followup')
      str += '.'
    else
      str += _('The request is <strong>waiting for clarification</strong>.')

      unless info_request.is_external?
        redirect_to = opts.fetch(:redirect_to)

        str += ' '
        str += _('If you are {{user_link}}, please',
                 :user_link => user_link_for_request(info_request))
        str += ' '
        str += link_to _("sign in"), signin_path(:r => redirect_to)
        str += ' '
        str += _('to send a follow up message.')
      end
    end

    str
  end

  def status_text_gone_postal(opts = {})
    _('The authority would like to / has <strong>responded by ' \
      'post</strong> to this request.')
  end

  def status_text_internal_review(opts = {})
    info_request = opts.fetch(:info_request)

    _('Waiting for an <strong>internal review</strong> by ' \
      '{{public_body_link}} of their handling of this request.',
      :public_body_link => public_body_link(info_request.public_body))
  end

  def status_text_error_message(opts = {})
    _('There was a <strong>delivery error</strong> or similar, which ' \
      'needs fixing by the {{site_name}} team.',
      :site_name => site_name)
  end

  def status_text_requires_admin(opts = {})
    _('This request has had an unusual response, and <strong>requires ' \
      'attention</strong> from the {{site_name}} team.',
      :site_name => site_name)
  end

  def status_text_user_withdrawn(opts = {})
    _('This request has been <strong>withdrawn</strong> by the person ' \
      'who made it. There may be an explanation in the correspondence below.')
  end

  def status_text_attention_requested(opts = {})
    _('This request has been <strong>reported</strong> as needing ' \
      'administrator attention (perhaps because it is vexatious, or a ' \
      'request for personal information)')
  end

  def status_text_vexatious(opts = {})
    _('This request has been <strong>hidden</strong> from the site, ' \
      'because an administrator considers it vexatious')
  end

  def status_text_not_foi(opts = {})
    _('This request has been <strong>hidden</strong> from the site, ' \
      'because an administrator considers it not to be an FOI request')
  end

  def custom_state_description(status)
    render :partial => 'general/custom_state_descriptions',
           :locals => { :status => status }
  end

end
