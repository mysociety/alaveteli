# models/outgoing_mailer.rb:
# Emails which go to public bodies on behalf of users.
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/

# Note: The layout for this wraps messages by lines rather than (blank line
# separated) paragraphs, as is the convention for all the other mailers. This
# turned out to fit better with user exepectations when formatting messages.
#
# XXX The other mail templates are written to use blank line separated
# paragraphs. They could be rewritten, and the wrapping method made uniform
# throughout the application.

class OutgoingMailer < ApplicationMailer

    # Email to public body requesting info
    def initial_request(info_request, outgoing_message)
        @wrap_lines_as_paragraphs = true
        @from = info_request.incoming_name_and_email
        @recipients = info_request.recipient_name_and_email
        @subject    = info_request.email_subject_request
        @headers["message-id"] = OutgoingMailer.id_for_message(outgoing_message)
        @body       = {:info_request => info_request, :outgoing_message => outgoing_message,
            :contact_email => Configuration::contact_email }
    end

    # Later message to public body regarding existing request
    def followup(info_request, outgoing_message, incoming_message_followup)
        @wrap_lines_as_paragraphs = true
        @from = info_request.incoming_name_and_email
        @recipients = OutgoingMailer.name_and_email_for_followup(info_request, incoming_message_followup)
        @subject    = OutgoingMailer.subject_for_followup(info_request, outgoing_message)
        @headers["message-id"] = OutgoingMailer.id_for_message(outgoing_message)
        @body       = {:info_request => info_request, :outgoing_message => outgoing_message,
            :incoming_message_followup => incoming_message_followup,
            :contact_email => Configuration::contact_email }
    end

    # XXX the condition checking valid_to_reply_to? also appears in views/request/_followup.rhtml,
    # it shouldn't really, should call something here.
    # XXX also OutgoingMessage.get_salutation
    # XXX these look like they should be members of IncomingMessage, but logically they
    # need to work even when IncomingMessage is nil
    def OutgoingMailer.name_and_email_for_followup(info_request, incoming_message_followup)
        if incoming_message_followup.nil? || !incoming_message_followup.valid_to_reply_to?
            return info_request.recipient_name_and_email
        else
            # calling safe_mail_from from so censor rules are run
            return TMail::Address.address_from_name_and_email(incoming_message_followup.safe_mail_from, incoming_message_followup.mail.from_addrs[0].spec).to_s
        end
    end
    # Used in the preview of followup
    def OutgoingMailer.name_for_followup(info_request, incoming_message_followup)
        if incoming_message_followup.nil? || !incoming_message_followup.valid_to_reply_to?
            return info_request.public_body.name
        else
            # calling safe_mail_from from so censor rules are run
            return incoming_message_followup.safe_mail_from || info_request.public_body.name
        end
    end
    # Used when making list of followup places to remove duplicates
    def OutgoingMailer.email_for_followup(info_request, incoming_message_followup)
        if incoming_message_followup.nil? || !incoming_message_followup.valid_to_reply_to?
            return info_request.recipient_email
        else
            return incoming_message_followup.mail.from_addrs[0].spec
        end
    end
    # Subject to use for followup
    def OutgoingMailer.subject_for_followup(info_request, outgoing_message)
        if outgoing_message.what_doing == 'internal_review'
            return "Internal review of " + info_request.email_subject_request
        else
            return info_request.email_subject_followup(outgoing_message.incoming_message_followup)
        end
    end
    # Whether we have a valid email address for a followup
    def OutgoingMailer.is_followupable?(info_request, incoming_message_followup)
        if incoming_message_followup.nil? || !incoming_message_followup.valid_to_reply_to?
            return info_request.recipient_email_valid_for_followup?
        else
            # email has been checked in incoming_message_followup.valid_to_reply_to? above
            return true
        end
    end
    # Message-ID to use
    def OutgoingMailer.id_for_message(outgoing_message)
        message_id = "ogm-" + outgoing_message.id.to_s
        t = Time.now
        message_id += "+" + '%08x%05x-%04x' % [t.to_i, t.tv_usec, rand(0xffff)]
        message_id += "@" + Configuration::incoming_email_domain
        return "<" + message_id + ">"
    end

end

