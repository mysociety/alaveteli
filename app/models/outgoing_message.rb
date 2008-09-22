# == Schema Information
# Schema version: 64
#
# Table name: outgoing_messages
#
#  id                           :integer         not null, primary key
#  info_request_id              :integer         not null
#  body                         :text            not null
#  status                       :string(255)     not null
#  message_type                 :string(255)     not null
#  created_at                   :datetime        not null
#  updated_at                   :datetime        not null
#  last_sent_at                 :datetime        
#  incoming_message_followup_id :integer         
#

# models/outgoing_message.rb:
# A message, associated with a request, from the user of the site to somebody
# else. e.g. An initial request for information, or a complaint.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: outgoing_message.rb,v 1.64 2008-09-22 02:36:04 francis Exp $

class OutgoingMessage < ActiveRecord::Base
    belongs_to :info_request
    validates_presence_of :info_request

    validates_inclusion_of :status, :in => ['ready', 'sent', 'failed']
    validates_inclusion_of :message_type, :in => ['initial_request', 'followup' ] #, 'complaint']

    belongs_to :incoming_message_followup, :foreign_key => 'incoming_message_followup_id', :class_name => 'IncomingMessage'

    # can have many events, for items which were resent by site admin e.g. if
    # contact address changed
    has_many :info_request_events 

    # How the default letter starts and ends
    def get_salutation
        ret = "Dear "
        if self.message_type == 'followup' && !self.incoming_message_followup.nil? && !self.incoming_message_followup.safe_mail_from.nil?
            ret = ret + self.incoming_message_followup.safe_mail_from
        else
            ret = ret + "Sir or Madam"
        end
        return ret + ","
    end
    def get_signoff
        if self.message_type == 'followup'
            return "Yours sincerely,"
        else
            return "Yours faithfully,"
        end
    end
    def get_default_message
        get_salutation + "\n\n\n\n" + get_signoff + "\n\n"
    end
    def set_signature_name(name)
        # XXX We use raw_body here to get unstripped one
        if self.raw_body == self.get_default_message
            self.body = self.raw_body + name 
        end
    end

    def body
        ret = read_attribute(:body)
        if ret.nil?
            return ret
        end
        ret = ret.strip
        ret = ret.gsub(/(?:\n\s*){2,}/, "\n\n") # remove excess linebreaks that unnecessarily space it out
        ret
    end
    def raw_body
        read_attribute(:body)
    end

    def body_without_salutation
        ret = self.body
        ret.sub!(/Dear .+,/, "")
        return ret
    end

    # Used to give warnings when writing new messages
    def contains_email?
        MySociety::Validate.email_find_regexp.match(self.body)
    end
    def contains_postcode?
        MySociety::Validate.contains_postcode?(self.body)
    end
 
    # Set default letter
    def after_initialize
        if self.body.nil?
            self.body = get_default_message
        end
    end

    # Check have edited letter
    def validate
        if self.body.empty? || self.body =~ /\A#{get_salutation}\s+#{get_signoff}/
            if self.message_type == 'followup'
                errors.add(:body, "^Please enter your follow up message")
            elsif
                errors.add(:body, "^Please enter your letter requesting information")
            else
                raise "Message id #{self.id} has type '#{self.message_type}' which validate can't handle"
            end
        end
        if self.body =~ /#{get_signoff}\s*\Z/ms
            errors.add(:body, '^Please sign at the bottom with your name, or alter the "' + get_signoff + '" signature')
        end
    end

    # Deliver outgoing message
    # Note: You can test this from script/console with, say:
    # InfoRequest.find(1).outgoing_messages[0].send_message
    def send_message(log_event_type = 'sent')
        if self.status == 'ready'
            if self.message_type == 'initial_request'
                RequestMailer.deliver_initial_request(self.info_request, self)
                self.last_sent_at = Time.now
                self.status = 'sent'
                self.save!
                self.info_request.log_event(log_event_type, { :email => self.info_request.recipient_name_and_email, :outgoing_message_id => self.id })
            elsif self.message_type == 'followup'
                RequestMailer.deliver_followup(self.info_request, self, self.incoming_message_followup)
                self.last_sent_at = Time.now
                self.status = 'sent'
                self.save!
                self.info_request.log_event('followup_' + log_event_type, { :email => RequestMailer.name_and_email_for_followup(self.info_request, self.incoming_message_followup), :outgoing_message_id => self.id })
                if self.info_request.described_state == 'waiting_clarification'
                    self.info_request.set_described_state('waiting_response')
                end
            else
                raise "Message id #{self.id} has type '#{self.message_type}' which send_message can't handle"
            end
        elsif self.status == 'sent'
            raise "Message id #{self.id} has already been sent"
        else
            raise "Message id #{self.id} not in state for send_message"
        end
    end

    # An admin function
    def resend_message
        if ['initial_request', 'followup'].include?(self.message_type) and self.status == 'sent'
            self.status = 'ready'
            send_message('resent')
        else
            raise "Message id #{self.id} has type '#{self.message_type}' status '#{self.status}' which resend_message can't handle"
        end
    end

    # Returns the text to quote the original message when sending this one
    def quoted_part_to_append_to_email
        if self.message_type == 'followup' && !self.incoming_message_followup.nil?
            return "\n\n-----Original Message-----\n\n" + self.incoming_message_followup.get_body_for_quoting + "\n"
        else
            return ""
        end
    end

    # Return body for display as HTML
    def get_body_for_html_display
        text = self.body.strip
        text = MySociety::Format.wrap_email_body(text) # reparagraph and wrap it so is good preview of emails
        text = CGI.escapeHTML(text)
        text = MySociety::Format.make_clickable(text, :contract => 1)
        text = text.gsub(/\n/, '<br>')
        return text
    end

end


