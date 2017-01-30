# -*- encoding : utf-8 -*-
module InfoRequestHelper
  include ConfigHelper
  include DateTimeHelper
  include LinkToHelper

  def status_text(info_request, opts = {})
    if info_request.awaiting_description
      status = "awaiting_description"
    else
      status = info_request.calculate_status
    end
    method = "status_text_#{ status }"
    if respond_to?(method, true)
      send(method, info_request, opts)
    else
      custom_state_description(info_request, opts)
    end
  end

  private

  def status_text_awaiting_description(info_request, opts = {})
    new_responses_count = opts.fetch(:new_responses_count, 0)
    is_owning_user = opts.fetch(:is_owning_user, false)
    render_to_file = opts.fetch(:render_to_file, false)
    old_unclassified = opts.fetch(:old_unclassified, false)

    if is_owning_user && !info_request.is_external? && !render_to_file
      return status_text_awaiting_description_owner_please_answer(
        new_responses_count)
    else
      if old_unclassified
        return status_text_awaiting_description_old_unclassified(
          new_responses_count)
      else
        return status_text_awaiting_description_other(info_request,
                                                      new_responses_count)
      end
    end
  end

  def status_text_waiting_response(info_request, opts = {})
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

  def status_text_waiting_response_overdue(info_request, opts = {})
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

  def status_text_waiting_response_very_overdue(info_request, opts = {})
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

  def status_text_not_held(info_request, opts = {})
    _('{{authority_name}} <strong>did not have</strong> the information ' \
      'requested.',
      :authority_name => public_body_link(info_request.public_body))
  end

  def status_text_rejected(info_request, opts = {})
    _('The request was <strong>refused</strong> by {{authority_name}}.',
      :authority_name => public_body_link(info_request.public_body))
  end

  def status_text_successful(info_request, opts = {})
    _('The request was <strong>successful</strong>.')
  end

  def status_text_partially_successful(info_request, opts = {})
    _('The request was <strong>partially successful</strong>.')
  end

  def status_text_waiting_clarification(info_request, opts = {})
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

  def status_text_gone_postal(info_request, opts = {})
    _('The authority would like to / has <strong>responded by ' \
      'post</strong> to this request.')
  end

  def status_text_internal_review(info_request, opts = {})
    _('Waiting for an <strong>internal review</strong> by ' \
      '{{public_body_link}} of their handling of this request.',
      :public_body_link => public_body_link(info_request.public_body))
  end

  def status_text_error_message(info_request, opts = {})
    _('There was a <strong>delivery error</strong> or similar, which ' \
      'needs fixing by the {{site_name}} team.',
      :site_name => site_name)
  end

  def status_text_requires_admin(info_request, opts = {})
    _('This request has had an unusual response, and <strong>requires ' \
      'attention</strong> from the {{site_name}} team.',
      :site_name => site_name)
  end

  def status_text_user_withdrawn(info_request, opts = {})
    _('This request has been <strong>withdrawn</strong> by the person ' \
      'who made it. There may be an explanation in the correspondence below.')
  end

  def status_text_attention_requested(info_request, opts = {})
    _('This request has been <strong>reported</strong> as needing ' \
      'administrator attention (perhaps because it is vexatious, or a ' \
      'request for personal information)')
  end

  def status_text_vexatious(info_request, opts = {})
    _('This request has been <strong>hidden</strong> from the site, ' \
      'because an administrator considers it vexatious')
  end

  def status_text_not_foi(info_request, opts = {})
    _('This request has been <strong>hidden</strong> from the site, ' \
      'because an administrator considers it not to be an FOI request')
  end

  def custom_state_description(info_request, opts = {})
    render :partial => 'general/custom_state_descriptions',
           :locals => { :status => info_request.calculate_status }
  end

  def status_text_awaiting_description_owner_please_answer(new_responses_count)
    n_('Please <strong>answer the question above</strong> so we know ' \
          'whether the recent response contains useful information.',
       'Please <strong>answer the question above</strong> so we know ' \
          'whether the recent responses contain useful information.',
        new_responses_count)
  end

  def status_text_awaiting_description_unknown
    _('This request has an <strong>unknown status</strong>.')
  end

  def status_text_awaiting_description_old_unclassified(new_responses_count)
    str = ''.html_safe
    str += status_text_awaiting_description_unknown
    str += ' '
    str += n_('We\'re waiting for someone to read a recent response and ' \
                'update the status accordingly. Perhaps ' \
                '<strong>you</strong> might like to help out by doing that?',
              'We\'re waiting for someone to read recent responses and ' \
                'update the status accordingly. Perhaps ' \
                '<strong>you</strong> might like to help out by doing that?',
              new_responses_count)
  end

  def status_text_awaiting_description_other(info_request, new_responses_count)
    n_('We\'re waiting for {{user}} to read a recent response and update ' \
         'the status.',
       'We\'re waiting for {{user}} to read recent responses and update ' \
         'the status.',
       new_responses_count,
       user: user_link_for_request(info_request))
  end

end
