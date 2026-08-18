# Composes the subject line for an OutgoingMessage's email
class OutgoingMessage::Subject
  def initialize(info_request:, html:, incoming_message: nil)
    @info_request = info_request
    @incoming_message = incoming_message
    @html = html
  end

  def initial_request
    _('{{law_used_full}} request - {{title}}',
      law_used_full: info_request.legislation.to_s(:full),
      title: html ? info_request.title : info_request.title.html_safe)
  end

  def followup
    if incoming_message.nil? ||
       !incoming_message.valid_to_reply_to? ||
       !incoming_message.subject
      'Re: ' + initial_request
    elsif incoming_message.subject.match(/^Re:/i)
      incoming_message.subject
    else
      'Re: ' + incoming_message.subject
    end
  end

  def internal_review
    _("Internal review of {{email_subject}}", email_subject: initial_request)
  end

  protected

  attr_reader :info_request, :incoming_message, :html
end
