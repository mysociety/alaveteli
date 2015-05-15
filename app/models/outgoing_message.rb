# -*- encoding : utf-8 -*-
# == Schema Information
# Schema version: 20131024114346
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
#  prominence                   :string(255)      default("normal"), not null
#  prominence_reason            :text
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

    # To override the default letter
    attr_accessor :default_letter

    validates_presence_of :info_request
    validates_inclusion_of :status, :in => ['ready', 'sent', 'failed']
    validates_inclusion_of :message_type, :in => ['initial_request', 'followup']
    validate :format_of_body

    belongs_to :info_request
    belongs_to :incoming_message_followup, :foreign_key => 'incoming_message_followup_id', :class_name => 'IncomingMessage'

    # can have many events, for items which were resent by site admin e.g. if
    # contact address changed
    has_many :info_request_events

    after_initialize :set_default_letter
    after_save :purge_in_cache
    # reindex if body text is edited (e.g. by admin interface)
    after_update :xapian_reindex_after_update

    strip_attributes!
    has_prominence

    self.default_url_options[:host] = AlaveteliConfiguration.domain

    # https links in emails if forcing SSL
    if AlaveteliConfiguration::force_ssl
      self.default_url_options[:protocol] = "https"
    end

    def self.default_salutation(public_body)
        _("Dear {{public_body_name}},", :public_body_name => public_body.name)
    end

    def self.placeholder_salutation
        _("Dear [Authority name],")
    end

    def self.fill_in_salutation(body, public_body)
        body.gsub(placeholder_salutation, default_salutation(public_body))
    end

    # How the default letter starts and ends
    def get_salutation
        if info_request.is_batch_request_template?
            return OutgoingMessage.placeholder_salutation
        end

        ret = ""
        if message_type == 'followup' &&
            !incoming_message_followup.nil? &&
            !incoming_message_followup.safe_mail_from.nil? &&
            incoming_message_followup.valid_to_reply_to?

            ret += OutgoingMailer.name_for_followup(info_request, incoming_message_followup)
        else
            return OutgoingMessage.default_salutation(info_request.public_body)
        end
        salutation = _("Dear {{public_body_name}},", :public_body_name => ret)
    end

    def get_signoff
        if message_type == 'followup' &&
            !incoming_message_followup.nil? &&
            !incoming_message_followup.safe_mail_from.nil? &&
            incoming_message_followup.valid_to_reply_to?

            _("Yours sincerely,")
        else
            _("Yours faithfully,")
        end
    end

    def get_internal_review_insert_here_note
        _("GIVE DETAILS ABOUT YOUR COMPLAINT HERE")
    end

    def get_default_letter
        return default_letter if default_letter

        if what_doing == 'internal_review'
            letter = _("Please pass this on to the person who conducts Freedom of Information reviews.")
            letter += "\n\n"
            letter += _("I am writing to request an internal review of {{public_body_name}}'s handling of my FOI request '{{info_request_title}}'.",
                          :public_body_name => info_request.public_body.name,
                          :info_request_title => info_request.title)
            letter += "\n\n\n\n [ #{ get_internal_review_insert_here_note } ] \n\n\n\n"
            letter += _("A full history of my FOI request and all correspondence is available on the Internet at this address: {{url}}",
                          :url => request_url(info_request))
            letter += "\n"
        else
            ""
        end
    end

    def get_default_message
        msg = get_salutation
        msg += "\n\n"
        msg += get_default_letter
        msg += "\n\n"
        msg += get_signoff
        msg += "\n\n"
    end

    def set_signature_name(name)
        # TODO: We use raw_body here to get unstripped one
        if raw_body == get_default_message
            self.body = raw_body + name
        end
    end

    # Public: The body text of the OutgoingMessage. The text is cleaned and
    # CensorRules are applied.
    #
    # options - Hash of options
    #           :censor_rules - Array of CensorRules to apply. Defaults to the
    #                           applicable_censor_rules of the associated
    #                           InfoRequest. (optional)
    #
    # Returns a String
    def body(options = {})
        text = raw_body.dup
        return text if text.nil?

        text = clean_text(text)

        # Use the given censor_rules; otherwise fetch them from the associated
        # info_request
        censor_rules = options.fetch(:censor_rules) do
            info_request.try(:applicable_censor_rules) or []
        end

        censor_rules.reduce(text) { |text, rule| rule.apply_to_text(text) }
    end

    def raw_body
        read_attribute(:body)
    end

    # Used to give warnings when writing new messages
    def contains_email?
        MySociety::Validate.email_find_regexp.match(body)
    end

    def contains_postcode?
        MySociety::Validate.contains_postcode?(body)
    end

    def record_email_delivery(to_addrs, message_id, log_event_type = 'sent')
        self.last_sent_at = Time.now
        self.status = 'sent'
        save!

        log_event_type = "followup_#{ log_event_type }" if message_type == 'followup'

        info_request.log_event(log_event_type, { :email => to_addrs,
                                                 :outgoing_message_id => id,
                                                 :smtp_message_id => message_id })
        set_info_request_described_state
    end

    def sendable?
        if status == 'ready'
            if message_type == 'initial_request'
                return true
            elsif message_type == 'followup'
                return true
            else
                raise "Message id #{id} has type '#{message_type}' which cannot be sent"
            end
        elsif status == 'sent'
            raise "Message id #{id} has already been sent"
        else
            raise "Message id #{id} not in state for sending"
        end
    end

    # An admin function
    def prepare_message_for_resend
        if ['initial_request', 'followup'].include?(message_type) and status == 'sent'
            self.status = 'ready'
        else
            raise "Message id #{id} has type '#{message_type}' status " \
                  "'#{status}' which prepare_message_for_resend can't handle"
        end
    end

    # Returns the text to quote the original message when sending this one
    def quoted_part_to_append_to_email
        if message_type == 'followup' && !incoming_message_followup.nil?
            quoted = "\n\n-----Original Message-----\n\n"
            quoted += incoming_message_followup.get_body_for_quoting
            quoted += "\n"
        else
            ""
        end
    end

    # We hide emails from display in outgoing messages.
    def remove_privacy_sensitive_things!(text)
        text.gsub!(MySociety::Validate.email_find_regexp, "[email address]")
    end

    # Returns text for indexing / text display
    def get_text_for_indexing(strip_salutation = true, opts = {})
        if opts.empty?
            text = body.strip
        else
            text = body(opts).strip
        end

        # Remove salutation
        text.sub!(/Dear .+,/, "") if strip_salutation

        # Remove email addresses from display/index etc.
        self.remove_privacy_sensitive_things!(text)

        text
    end

    # Return body for display as HTML
    def get_body_for_html_display
        text = body.strip
        self.remove_privacy_sensitive_things!(text)
        # reparagraph and wrap it so is good preview of emails
        text = MySociety::Format.wrap_email_body_by_lines(text)
        text = CGI.escapeHTML(text)
        text = MySociety::Format.make_clickable(text, :contract => 1)
        text.gsub!(/\[(email address|mobile number)\]/, '[<a href="/help/officers#mobiles">\1</a>]')
        text = text.gsub(/\n/, '<br>')
        text.html_safe
    end

    # Return body for display as text
    def get_body_for_text_display
         get_text_for_indexing(strip_salutation=false)
    end


    def fully_destroy
        ActiveRecord::Base.transaction do
            info_request_event = InfoRequestEvent.find_by_outgoing_message_id(id)
            info_request_event.track_things_sent_emails.each { |a| a.destroy }
            info_request_event.user_info_request_sent_alerts.each { |a| a.destroy }
            info_request_event.destroy
            destroy
        end
    end

    def purge_in_cache
        info_request.purge_in_cache
    end

    def for_admin_column
        self.class.content_columns.each do |column|
            yield(column.human_name, self.send(column.name), column.type.to_s, column.name)
        end
    end

    def xapian_reindex_after_update
        if changes.include?('body')
            info_request_events.each do |event|
                event.xapian_mark_needs_index
            end
        end
    end

    private

    def set_info_request_described_state
        if message_type == 'initial_request'
            info_request.set_described_state('waiting_response')
        elsif message_type == 'followup'
            if info_request.described_state == 'waiting_clarification'
                info_request.set_described_state('waiting_response')
            end
            if what_doing == 'internal_review'
                info_request.set_described_state('internal_review')
            end
        end
    end

    def set_default_letter
        self.body = get_default_message if raw_body.nil?
    end

    def format_of_body
        if body.empty? || body =~ /\A#{Regexp.escape(get_salutation)}\s+#{Regexp.escape(get_signoff)}/ || body =~ /#{Regexp.escape(get_internal_review_insert_here_note)}/
            if message_type == 'followup'
                if what_doing == 'internal_review'
                    errors.add(:body, _("Please give details explaining why you want a review"))
                else
                    errors.add(:body, _("Please enter your follow up message"))
                end
            elsif
                errors.add(:body, _("Please enter your letter requesting information"))
            else
                raise "Message id #{id} has type '#{message_type}' which validate can't handle"
            end
        end

        if body =~ /#{get_signoff}\s*\Z/m
            errors.add(:body, _("Please sign at the bottom with your name, or alter the \"{{signoff}}\" signature", :signoff => get_signoff))
        end

        unless MySociety::Validate.uses_mixed_capitals(body)
            errors.add(:body, _('Please write your message using a mixture of capital and lower case letters. This makes it easier for others to read.'))
        end

        if what_doing.nil? || !['new_information', 'internal_review', 'normal_sort'].include?(what_doing)
            errors.add(:what_doing_dummy, _('Please choose what sort of reply you are making.'))
        end
    end

    # remove excess linebreaks that unnecessarily space it out
    def clean_text(text)
        text.strip.gsub(/(?:\n\s*){2,}/, "\n\n")
    end
end


