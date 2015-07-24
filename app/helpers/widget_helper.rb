# -*- encoding : utf-8 -*-
module WidgetHelper
  def status_description(info_request, status)
    case status
    when 'waiting_classification'
      _('Awaiting classification')
    when 'waiting_response'
      _('Awaiting response')
    when 'waiting_response_overdue'
      _('Delayed')
    when 'waiting_response_very_overdue'
      _('Long overdue')
    when 'not_held'
      _('Not held')
    when 'rejected'
      _('Rejected')
    when 'successful'
      _('Successful')
    when 'partially_successful'
      _('Partial success')
    when 'waiting_clarification'
      _('Awaiting clarification')
    when 'gone_postal'
      _('Handled by post')
    when 'internal_review'
      _('Internal review')
    when 'error_message'
      _('Delivery error')
    when 'requires_admin'
      _('Unusual response')
    when 'user_withdrawn'
      _('Withdrawn')
    when 'attention_requested'
      _('Needs admin attention')
    when 'vexatious'
      _('Vexatious')
    when 'not_foi'
      _('Not an FOI request')
    else
      if info_request.respond_to?(:theme_display_status)
        info_request.theme_display_status(status)
      else
        _('Unknown')
      end
    end
  end
end
