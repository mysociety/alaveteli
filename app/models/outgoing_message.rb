# == Schema Information
#
# Table name: outgoing_messages
#
#  id                           :integer          not null, primary key
#  info_request_id              :integer          not null
#  body                         :text             not null
#  status                       :string(255)      not null
#  message_type                 :string(255)      not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  last_sent_at                 :datetime
#  incoming_message_followup_id :integer
#  what_doing                   :string(255)      not null
#

# models/outgoing_message.rb:
# A message, associated with a request, from the user of the site to somebody
# else. e.g. An initial request for information, or a complaint.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class OutgoingMessage < ActiveRecord::Base
    extend MessageProminence
    include Rails.application.routes.url_helpers
    include LinkToHelper
    self.default_url_options[:host] = AlaveteliConfiguration::domain
    # https links in emails if forcing SSL
    if AlaveteliConfiguration::force_ssl
      self.default_url_options[:protocol] = "https"
    end

    strip_attributes!

    has_prominence

    belongs_to :info_request
    validates_presence_of :info_request

    validates_inclusion_of :status, :in => ['ready', 'sent', 'failed']
    validates_inclusion_of :message_type, :in => ['initial_request', 'followup' ] #, 'complaint']
    validate :format_of_body

    belongs_to :incoming_message_followup, :foreign_key => 'incoming_message_followup_id', :class_name => 'IncomingMessage'

    # can have many events, for items which were resent by site admin e.g. if
    # contact address changed
    has_many :info_request_events

    # To override the default letter
    attr_accessor :default_letter

    # reindex if body text is edited (e.g. by admin interface)
    after_update :xapian_reindex_after_update
    def xapian_reindex_after_update
        if self.changes.include?('body')
            for info_request_event in self.info_request_events
                info_request_event.xapian_mark_needs_index
            end
        end
    end

    after_initialize :set_default_letter

    # How the default letter starts and ends
    def get_salutation
        ret = ""
        if self.message_type == 'followup' && !self.incoming_message_followup.nil? && !self.incoming_message_followup.safe_mail_from.nil? && self.incoming_message_followup.valid_to_reply_to?
            ret = ret + OutgoingMailer.name_for_followup(self.info_request, self.incoming_message_followup)
        else
            ret = ret + self.info_request.public_body.name
        end
        salutation = _("Dear {{public_body_name}},", :public_body_name => ret)
    end

    def get_signoff
        if self.message_type == 'followup' && !self.incoming_message_followup.nil? && !self.incoming_message_followup.safe_mail_from.nil? && self.incoming_message_followup.valid_to_reply_to?
            return _("Yours sincerely,")
        else
            return _("Yours faithfully,")
        end
    end
    def get_internal_review_insert_here_note
        return _("GIVE DETAILS ABOUT YOUR COMPLAINT HERE")
    end
    def get_default_letter
        if self.default_letter
            return self.default_letter
        end

        if self.what_doing == 'internal_review'
            _("Please pass this on to the person who conducts Freedom of Information reviews.") +
            "\n\n" +
            _("I am writing to request an internal review of {{public_body_name}}'s handling of my FOI request '{{info_request_title}}'.",
              :public_body_name => self.info_request.public_body.name,
              :info_request_title => self.info_request.title) +
            "\n\n\n\n [ " + self.get_internal_review_insert_here_note + " ] \n\n\n\n" +
            _("A full history of my FOI request and all correspondence is available on the Internet at this address: {{url}}",
            :url => request_url(self.info_request)) +
            "\n"
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

        ret = ret.dup
        ret.strip!
        ret.gsub!(/(?:\n\s*){2,}/, "\n\n") # remove excess linebreaks that unnecessarily space it out

        # Remove things from censor rules
        if !self.info_request.nil?
            self.info_request.apply_censor_rules_to_text!(ret)
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

    # Deliver outgoing message
    # Note: You can test this from script/console with, say:
    # InfoRequest.find(1).outgoing_messages[0].send_message
    def send_message(log_event_type = 'sent')
        if self.status == 'ready'
            if self.message_type == 'initial_request'
                self.last_sent_at = Time.now
                self.status = 'sent'
                self.save!

                mail_message = OutgoingMailer.initial_request(self.info_request, self).deliver
                self.info_request.log_event(log_event_type, {
                    :email => mail_message.to_addrs.join(", "),
                    :outgoing_message_id => self.id,
                    :smtp_message_id => mail_message.message_id
                })
                self.info_request.set_described_state('waiting_response')
            elsif self.message_type == 'followup'
                self.last_sent_at = Time.now
                self.status = 'sent'
                self.save!

                mail_message = OutgoingMailer.followup(self.info_request, self, self.incoming_message_followup).deliver
                self.info_request.log_event('followup_' + log_event_type, {
                    :email => mail_message.to_addrs.join(", "),
                    :outgoing_message_id => self.id,
                    :smtp_message_id => mail_message.message_id
                })
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
    def remove_privacy_sensitive_things!(text)
        text.gsub!(MySociety::Validate.email_find_regexp, "[email address]")
    end

    # Returns text for indexing / text display
    def get_text_for_indexing(strip_salutation=true)
        text = self.body.strip

        # Remove salutation
        text.sub!(/Dear .+,/, "") if strip_salutation

        # Remove email addresses from display/index etc.
        self.remove_privacy_sensitive_things!(text)

        return text
    end

    # Return body for display as HTML
    def get_body_for_html_display
        text = self.body.strip
        self.remove_privacy_sensitive_things!(text)
        text = MySociety::Format.wrap_email_body_by_lines(text) # reparagraph and wrap it so is good preview of emails
        text = CGI.escapeHTML(text)
        text = MySociety::Format.make_clickable(text, :contract => 1)
        text.gsub!(/\[(email address|mobile number)\]/, '[<a href="/help/officers#mobiles">\1</a>]')
        text = text.gsub(/\n/, '<br>')
        return text.html_safe
    end

    # Return body for display as text
    def get_body_for_text_display
         get_text_for_indexing(strip_salutation=false)
    end


    def fully_destroy
        ActiveRecord::Base.transaction do
            info_request_event = InfoRequestEvent.find_by_outgoing_message_id(self.id)
            info_request_event.track_things_sent_emails.each { |a| a.destroy }
            info_request_event.user_info_request_sent_alerts.each { |a| a.destroy }
            info_request_event.destroy
            self.destroy
        end
    end

    after_save(:purge_in_cache)
    def purge_in_cache
        self.info_request.purge_in_cache
    end

    def for_admin_column
        self.class.content_columns.each do |column|
            yield(column.human_name, self.send(column.name), column.type.to_s, column.name)
        end
    end

    private

    def set_default_letter
        if self.body.nil?
            self.body = get_default_message
        end
    end

    def format_of_body
        if self.body.empty? || self.body =~ /\A#{Regexp.escape(get_salutation)}\s+#{Regexp.escape(get_signoff)}/ || self.body =~ /#{Regexp.escape(get_internal_review_insert_here_note)}/
            if self.message_type == 'followup'
                if self.what_doing == 'internal_review'
                    errors.add(:body, _("Please give details explaining why you want a review"))
                else
                    errors.add(:body, _("Please enter your follow up message"))
                end
            elsif
                errors.add(:body, _("Please enter your letter requesting information"))
            else
                raise "Message id #{self.id} has type '#{self.message_type}' which validate can't handle"
            end
        end
        if self.body =~ /#{get_signoff}\s*\Z/m
            errors.add(:body, _("Please sign at the bottom with your name, or alter the \"{{signoff}}\" signature", :signoff => get_signoff))
        end
        if !MySociety::Validate.uses_mixed_capitals(self.body)
            errors.add(:body, _('Please write your message using a mixture of capital and lower case letters. This makes it easier for others to read.'))
        end
        if self.what_doing.nil? || !['new_information', 'internal_review', 'normal_sort'].include?(self.what_doing)
            errors.add(:what_doing_dummy, _('Please choose what sort of reply you are making.'))
        end
    end
end


