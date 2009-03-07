# == Schema Information
# Schema version: 72
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
#  what_doing                   :string(255)     not null
#

# models/outgoing_message.rb:
# A message, associated with a request, from the user of the site to somebody
# else. e.g. An initial request for information, or a complaint.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: outgoing_message.rb,v 1.80 2009-03-07 01:16:18 francis Exp $

class OutgoingMessage < ActiveRecord::Base
    strip_attributes!

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
        if self.message_type == 'followup' && !self.incoming_message_followup.nil? && !self.incoming_message_followup.safe_mail_from.nil? && self.incoming_message_followup.valid_to_reply_to?
            ret = ret + RequestMailer.name_for_followup(self.info_request, self.incoming_message_followup)
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
    def get_default_letter
        if self.what_doing == 'internal_review'
            "Please pass this on to the person who conducts Freedom of Information reviews." +
            "\n\n" +
            "I am writing to request an internal review of " +
            self.info_request.public_body.name +
            "'s handling of my FOI request " + 
            "'" + self.info_request.title + "'." + 
            "\n\n" +
            "A full history of my FOI request and all correspondence is available on the Internet at this address:\n" +
            "http://" + MySociety::Config.get("DOMAIN", '127.0.0.1:3000') + "/request/" + self.info_request.url_title 
        else
            ""
        end
    end
    def get_default_message
        get_salutation + "\n\n" + get_default_letter + "\n\n" + get_signoff + "\n\n"
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

        # Remove things from censor rules
        if !self.info_request.nil?
            ret = self.info_request.apply_censor_rules_to_text(ret)
        end

        ret
    end
    def raw_body
        read_attribute(:body)
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
        if self.what_doing.nil? || !['new_information', 'internal_review', 'normal_sort'].include?(self.what_doing)

            errors.add(:what_doing_dummy, '^Please choose what sort of reply you are making.')
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
                self.info_request.set_described_state('waiting_response')
            elsif self.message_type == 'followup'
                RequestMailer.deliver_followup(self.info_request, self, self.incoming_message_followup)
                self.last_sent_at = Time.now
                self.status = 'sent'
                self.save!
                self.info_request.log_event('followup_' + log_event_type, { :email => RequestMailer.name_and_email_for_followup(self.info_request, self.incoming_message_followup), :outgoing_message_id => self.id })
                if self.info_request.described_state == 'waiting_clarification'
                    self.info_request.set_described_state('waiting_response')
                end
                if self.what_doing == 'internal_review'
                    self.info_request.set_described_state('internal_review')
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

    # We hide emails from display in outgoing messages.
    def remove_privacy_sensitive_things(text)
        text = text.dup
        text.gsub!(MySociety::Validate.email_find_regexp, "[email address]")
        return text
    end

    # Returns text for indexing / text display
    def get_text_for_indexing
        text = self.body.strip

        # Remove salutation
        text.sub!(/Dear .+,/, "")

        # Remove email addresses from display/index etc.
        text = self.remove_privacy_sensitive_things(text)

        return text
    end

    # Return body for display as HTML
    def get_body_for_html_display
        text = self.body.strip
        text = self.remove_privacy_sensitive_things(text)
        text = MySociety::Format.wrap_email_body(text) # reparagraph and wrap it so is good preview of emails
        text = CGI.escapeHTML(text)
        text = MySociety::Format.make_clickable(text, :contract => 1)
        text = text.gsub(/\n/, '<br>')
        return text
    end

end


