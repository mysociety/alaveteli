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
  include AdminColumn
  extend MessageProminence
  include Rails.application.routes.url_helpers
  include LinkToHelper

  STATUS_TYPES = %w(ready sent failed).freeze
  MESSAGE_TYPES = %w(initial_request followup).freeze
  WHAT_DOING_VALUES = %w(normal_sort
                         internal_review
                         external_review
                         new_information).freeze

  # To override the default letter
  attr_accessor :default_letter

  validates_presence_of :info_request
  validates_inclusion_of :status, :in => STATUS_TYPES
  validates_inclusion_of :message_type, :in => MESSAGE_TYPES
  validate :template_changed
  validate :body_uses_mixed_capitals
  validate :body_has_signature
  validate :what_doing_value

  belongs_to :info_request
  belongs_to :incoming_message_followup, :foreign_key => 'incoming_message_followup_id', :class_name => 'IncomingMessage'

  # can have many events, for items which were resent by site admin e.g. if
  # contact address changed
  has_many :info_request_events, :dependent => :destroy

  after_initialize :set_default_letter
  after_save :purge_in_cache
  # reindex if body text is edited (e.g. by admin interface)
  after_update :xapian_reindex_after_update

  strip_attributes :allow_empty => true
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
    warn %q([DEPRECATION] OutgoingMessage.placeholder_salutation will be
            replaced with
            OutgoingMessage::Template::BatchRequest.placeholder_salutation as of
            0.25).squish
    Template::BatchRequest.placeholder_salutation
  end

  def self.fill_in_salutation(text, public_body)
    text.gsub(Template::BatchRequest.placeholder_salutation,
              default_salutation(public_body))
  end

  def get_internal_review_insert_here_note
    _("GIVE DETAILS ABOUT YOUR COMPLAINT HERE")
  end

  def get_default_message
    letter_template.body(default_message_replacements)
  end

  def set_signature_name(name)
    # TODO: We use raw_body here to get unstripped one
    if raw_body == get_default_message
      self.body = raw_body + name
    end
  end

  # Public: The value to be used in the From: header of an OutgoingMailer
  # message.
  #
  # Returns a String
  def from
    info_request.incoming_name_and_email
  end

  # Public: The value to be used in the To: header of an OutgoingMailer message.
  #
  # Returns a String
  def to
    if replying_to_incoming_message?
      # calling safe_mail_from from so censor rules are run
      MailHandler.address_from_name_and_email(incoming_message_followup.safe_mail_from,
                                              incoming_message_followup.from_email)
    else
      info_request.recipient_name_and_email
    end
  end

  # Public: The value to be used in the Subject: header of an OutgoingMailer
  # message.
  #
  # Returns a String
  def subject
    if message_type == 'followup'
      if what_doing == 'internal_review'
        _("Internal review of {{email_subject}}",
          :email_subject => info_request.email_subject_request(:html => false))
      else
        info_request.
          email_subject_followup(:incoming_message => incoming_message_followup,
                                 :html => false)
      end
    else
      info_request.email_subject_request(:html => false)
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

  def apply_masks(text, content_type)
    info_request.apply_masks(text, content_type)
  end

  # Used to give warnings when writing new messages
  def contains_email?
    MySociety::Validate.email_find_regexp.match(body)
  end

  def contains_postcode?
    MySociety::Validate.contains_postcode?(body)
  end

  def is_owning_user?(user)
    info_request.is_owning_user?(user)
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

  # Public: Return logged Message-ID attributes for this OutgoingMessage.
  # Note that these are not the MTA ID: https://en.wikipedia.org/wiki/Message-ID
  #
  # Returns an Array
  def smtp_message_ids
    info_request_events.
      order('created_at ASC').
        map { |event| event.params[:smtp_message_id] }.
          compact.
            map do |smtp_id|
              smtp_id.match(/<(.*)>/) { |m| m.captures.first } || smtp_id
            end
  end

  # Public: Return logged MTA IDs for this OutgoingMessage.
  #
  # Returns an Array
  def mta_ids
    case AlaveteliConfiguration.mta_log_type.to_sym
    when :exim
      exim_mta_ids
    when :postfix
      postfix_mta_ids
    else
      raise 'Unexpected MTA type'
    end
  end

  # Public: Return the MTA logs for this message.
  #
  # Returns an Array.
  def mail_server_logs
    case AlaveteliConfiguration.mta_log_type.to_sym
    when :exim
      exim_mail_server_logs
    when :postfix
      postfix_mail_server_logs
    else
      raise 'Unexpected MTA type'
    end
  end

  def delivery_status
    mail_server_logs.
      map { |log| log.line(:decorate => true).delivery_status }.
        compact.
          last
  end

  # An admin function
  def prepare_message_for_resend
    if MESSAGE_TYPES.include?(message_type) and status == 'sent'
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
    text = CGI.escapeHTML(text)
    text = MySociety::Format.make_clickable(text, :contract => 1)
    text.gsub!(/\[(email address|mobile number)\]/, '[<a href="/help/officers#mobiles">\1</a>]')
    text = ActionController::Base.helpers.simple_format(text)
    text.html_safe
  end

  # Return body for display as text
  def get_body_for_text_display
    get_text_for_indexing(strip_salutation=false)
  end

  def purge_in_cache
    info_request.purge_in_cache
  end

  def xapian_reindex_after_update
    if changes.include?('body')
      info_request_events.each do |event|
        event.xapian_mark_needs_index
      end
    end
  end

  # How the default letter starts and ends
  def get_salutation
    warn %q([DEPRECATION] OutgoingMessage#get_salutation will be replaced with
            OutgoingMessage::Template classes in 0.25).squish

    if info_request.is_batch_request_template?
      return OutgoingMessage.placeholder_salutation
    end

    ret = ""
    if replying_to_incoming_message?
      ret += OutgoingMailer.name_for_followup(info_request, incoming_message_followup)
    else
      return OutgoingMessage.default_salutation(info_request.public_body)
    end
    salutation = _("Dear {{public_body_name}},", :public_body_name => ret)
  end

  def get_signoff
    warn %q([DEPRECATION] OutgoingMessage#get_signoff will be replaced with
            OutgoingMessage::Template classes in 0.25).squish

    if replying_to_incoming_message?
      _("Yours sincerely,")
    else
      _("Yours faithfully,")
    end
  end

  def get_default_letter
    warn %q([DEPRECATION] OutgoingMessage#get_default_letter will be replaced
            with OutgoingMessage::Template classes in 0.25).squish

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

  def letter_template
    @letter_template ||=
      if what_doing == 'internal_review'
        Template::InternalReview.new
      elsif info_request.is_batch_request_template?
        Template::BatchRequest.new
      elsif replying_to_incoming_message?
        Template::IncomingMessageFollowup.new
      else
        Template::InitialRequest.new
      end
  end

  def default_message_replacements
    opts = {}

    if info_request
      opts[:url] = request_url(info_request) if info_request.url_title
      opts[:info_request_title] = info_request.title if info_request.title
    end

    opts[:public_body_name] =
      if replying_to_incoming_message?
        OutgoingMailer.
          name_for_followup(info_request, incoming_message_followup)
      else
        info_request.try(:public_body).try(:name)
      end

    opts[:letter] = default_letter if default_letter

    opts
  end

  def replying_to_incoming_message?
    message_type == 'followup' &&
      incoming_message_followup &&
        incoming_message_followup.safe_mail_from &&
          incoming_message_followup.valid_to_reply_to?
  end

  def format_of_body
    warn %q([DEPRECATION] OutgoingMessage#format_of_body will be removed in
            0.26. It has been broken up in to OutgoingMessage#template_changed,
            OutgoingMessage#body_uses_mixed_capitals,
            OutgoingMessage#body_has_signature and
            OutgoingMessage#what_doing_value).squish
    template_changed
    body_uses_mixed_capitals
    body_has_signature
    what_doing_value
  end

  def template_changed
    if body.empty? || HTMLEntities.new.decode(raw_body) =~ /\A#{template_regex(letter_template.body(default_message_replacements))}/
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
  end

  def template_regex(template_text)
    text = template_text.gsub("\r", "\n") # in case we have '\r\n' or even '\r's all the way down
    # feels like this should need a gsub(/\//, '\/') but doesn't seem to
    Regexp.escape(text.squeeze("\n")).
      gsub("\\n", '\s*').
      gsub('\ \s*', '\s*').
      gsub('\s*\ ', '\s*')
  end

  def body_has_signature
    if raw_body =~ /#{template_regex(letter_template.signoff(default_message_replacements))}\s*\Z/m
      errors.add(:body, _("Please sign at the bottom with your name, or alter the \"{{signoff}}\" signature", :signoff => letter_template.signoff(default_message_replacements)))
    end
  end

  def body_uses_mixed_capitals
    unless MySociety::Validate.uses_mixed_capitals(body)
      errors.add(:body, _('Please write your message using a mixture of capital and lower case letters. This makes it easier for others to read.'))
    end
  end

  def what_doing_value
    if what_doing.nil? || !WHAT_DOING_VALUES.include?(what_doing)
      errors.add(:what_doing_dummy, _('Please choose what sort of reply you are making.'))
    end
  end

  def exim_mta_ids
    lines = smtp_message_ids.map do |smtp_message_id|
      info_request.
        mail_server_logs.
          where("line ILIKE :q", q: "%#{ smtp_message_id }%").
            where("line ILIKE :marker", marker: "%<=%").
              last.
                try(:line)
    end

    lines.compact.map { |line| line.split(' ').fourth.strip }
  end

  def exim_mail_server_logs
    mta_ids.flat_map do |mta_id|
      info_request.
        mail_server_logs.
          where('line ILIKE :mta_id', mta_id: "%#{ mta_id }%")
    end
  end

  def postfix_mta_ids
    lines = smtp_message_ids.map do |smtp_message_id|
      info_request.
        mail_server_logs.
          where("line ILIKE :q", q: "%#{ smtp_message_id }%").
              last.
                try(:line)
    end
    lines.compact.map { |line| line.split(' ')[5].strip.chomp(':') }
  end

  def postfix_mail_server_logs
    mta_ids.flat_map do |mta_id|
      info_request.
        mail_server_logs.
          where('line ILIKE :mta_id', mta_id: "%#{ mta_id }%")
    end
  end

  # remove excess linebreaks that unnecessarily space it out
  def clean_text(text)
    text.strip.gsub(/(?:\n\s*){2,}/, "\n\n")
  end
end
