# == Schema Information
# Schema version: 20230718062820
#
# Table name: outgoing_messages
#
#  id                           :integer          not null, primary key
#  info_request_id              :integer          not null
#  body                         :text             not null
#  status                       :string           not null
#  message_type                 :string           not null
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  last_sent_at                 :datetime
#  incoming_message_followup_id :integer
#  what_doing                   :string           not null
#  prominence                   :string           default("normal"), not null
#  prominence_reason            :text
#  from_name                    :text
#

# models/outgoing_message.rb:
# A message, associated with a request, from the user of the site to somebody
# else. e.g. An initial request for information, or a complaint.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class OutgoingMessage < ApplicationRecord
  include MessageProminence
  include Rails.application.routes.url_helpers
  include LinkToHelper
  include Taggable

  STATUS_TYPES = %w(ready sent failed).freeze
  MESSAGE_TYPES = %w(initial_request followup).freeze
  WHAT_DOING_VALUES = %w(normal_sort
                         internal_review
                         external_review
                         new_information).freeze

  # To override the default letter
  attr_accessor :default_letter

  before_validation :cache_from_name
  validates_presence_of :info_request
  validates_presence_of :from_name, unless: -> (m) { !m.info_request&.user }
  validates_inclusion_of :status, in: STATUS_TYPES
  validates_inclusion_of :message_type, in: MESSAGE_TYPES
  validate :template_changed
  validate :body_uses_mixed_capitals
  validate :body_has_signature
  validate :what_doing_value

  belongs_to :info_request,
             inverse_of: :outgoing_messages
  belongs_to :incoming_message_followup,
             inverse_of: :outgoing_message_followups,
             foreign_key: 'incoming_message_followup_id',
             class_name: 'IncomingMessage'

  has_one :user,
          inverse_of: :outgoing_messages,
          through: :info_request

  # can have many events, for items which were resent by site admin e.g. if
  # contact address changed
  has_many :info_request_events,
           inverse_of: :outgoing_message,
           dependent: :destroy

  delegate :public_body, to: :info_request, private: true, allow_nil: true

  after_initialize :set_default_letter
  # reindex if body text is edited (e.g. by admin interface)
  after_update :xapian_reindex_after_update

  strip_attributes allow_empty: true

  admin_columns include: [:to, :from, :subject]

  default_url_options[:host] = AlaveteliConfiguration.domain

  scope :followup, -> { where(message_type: 'followup') }
  scope :is_searchable, -> { where(prominence: 'normal') }

  def self.expected_send_errors
    [ EOFError,
      IOError,
      Timeout::Error,
      Errno::ECONNRESET,
      Errno::ECONNABORTED,
      Errno::EPIPE,
      Errno::ETIMEDOUT,
      Net::SMTPAuthenticationError,
      Net::SMTPServerBusy,
      Net::SMTPSyntaxError,
      Net::SMTPUnknownError,
      OpenSSL::SSL::SSLError ].concat(additional_send_errors)
  end

  def self.additional_send_errors
    []
  end

  def self.default_salutation(public_body)
    _("Dear {{public_body_name}},", public_body_name: public_body.name)
  end

  def self.fill_in_salutation(text, public_body)
    text.gsub(Template::BatchRequest.placeholder_salutation,
              default_salutation(public_body))
  end

  def self.with_body(body)
    # TODO: can add other databases here which have regexp_replace
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      # Exclude whitespace from the body comparison using regexp_replace
      where("regexp_replace(outgoing_messages.body, '[[:space:]]', '', 'g') =
             regexp_replace(?, '[[:space:]]', '', 'g')", body)
    else
      # For other databases (e.g. SQLite) not the end of the world being space-sensitive for this check
      where(body: body)
    end
  end

  def get_internal_review_insert_here_note
    _("GIVE DETAILS ABOUT YOUR COMPLAINT HERE")
  end

  def get_default_message
    letter_template.body(default_message_replacements)
  end

  def set_signature_name(name)
    # We compare against raw_body as body strips linebreaks and applies
    # censor rules
    self.body = get_default_message + name if raw_body == get_default_message
  end

  def from_name
    return info_request.external_user_name if info_request.is_external?
    super || info_request.user_name
  end

  def safe_from_name
    return info_request.external_user_name if info_request.is_external?
    info_request.apply_censor_rules_to_text(from_name)
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
      # calling safe_from_name from so censor rules are run
      MailHandler.address_from_name_and_email(incoming_message_followup.safe_from_name,
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
          email_subject: info_request.email_subject_request(html: false))
      else
        info_request.
          email_subject_followup(incoming_message: incoming_message_followup,
                                 html: false)
      end
    else
      info_request.email_subject_request(html: false)
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

    censor_rules.reduce(text) { |t, rule| rule.apply_to_text(t) }
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

  # Without recording the send failure, parts of the public and admin
  # interfaces for the request and authority may become inaccessible.
  def record_email_failure(failure_reason)
    self.last_sent_at = Time.zone.now
    self.status = 'failed'
    save!

    info_request.log_event(
      'send_error',
      reason: failure_reason,
      outgoing_message_id: id
    )
    set_info_request_described_state
  end

  def record_email_delivery(to_addrs, message_id, log_event_type = 'sent')
    self.last_sent_at = Time.zone.now
    self.status = 'sent'
    save!

    if message_type == 'followup'
      log_event_type = "followup_#{ log_event_type }"
    end

    info_request.log_event(
      log_event_type,
      email: to_addrs,
      outgoing_message_id: id,
      smtp_message_id: message_id
    )
    set_info_request_described_state
  end

  def sendable?
    if status == 'ready'
      if message_type == 'initial_request'
        true
      elsif message_type == 'followup'
        true
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
      order(:created_at).
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
    # If the outgoing status is failed, we won't have mail logs, and know we can
    # present a failed status to the end user.
    if status == 'failed'
      MailServerLog::DeliveryStatus.new(:failed)
    else
      mail_server_logs.map(&:delivery_status).compact.reject(&:unknown?).last ||
        MailServerLog::DeliveryStatus.new(:unknown)
    end
  end

  # An admin function
  def prepare_message_for_resend
    if MESSAGE_TYPES.include?(message_type) &&
         (status == 'sent' || status == 'failed')
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

    if strip_salutation && public_body
      salutation = self.class.default_salutation(public_body)
      text.sub!(/#{Regexp.escape(salutation)}\s*/, '')
    end

    # Remove email addresses from display/index etc.
    remove_privacy_sensitive_things!(text)

    text
  end

  # Return body for display as HTML
  def get_body_for_html_display
    text = body.strip
    remove_privacy_sensitive_things!(text)
    text = CGI.escapeHTML(text)
    text = MySociety::Format.make_clickable(text, { contract: 1, nofollow: true })
    text.gsub!(/\[(email address|mobile number)\]/, '[<a href="/help/officers#mobiles">\1</a>]')
    text = ActionController::Base.helpers.simple_format(text)
    text.html_safe
  end

  # Return body for display as text
  def get_body_for_text_display
    get_text_for_indexing(strip_salutation=false)
  end

  def xapian_reindex_after_update
    return unless saved_change_to_attribute?(:body)

    info_request_events.find_each(&:xapian_mark_needs_index)
  end

  def default_letter=(text)
    original_default = get_default_message.clone
    @default_letter = text
    self.body = get_default_message if raw_body == original_default
  end

  private

  def cache_from_name
    return if read_attribute(:from_name)
    self.from_name = info_request.user_name if info_request
  end

  def set_info_request_described_state
    if status == 'failed'
      info_request.set_described_state('error_message')
    elsif message_type == 'initial_request'
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
      opts[:embargo] = true if info_request.embargo
    end

    opts[:public_body_name] =
      if replying_to_incoming_message?
        OutgoingMailer.
          name_for_followup(info_request, incoming_message_followup)
      else
        public_body&.name
      end

    opts[:letter] = default_letter if default_letter

    opts
  end

  def replying_to_incoming_message?
    message_type == 'followup' &&
      incoming_message_followup &&
      incoming_message_followup.safe_from_name &&
      incoming_message_followup.valid_to_reply_to?
  end

  def template_changed
    if raw_body.empty? || HTMLEntities.new.decode(raw_body) =~
                          /\A#{template_regex(letter_template.body(default_message_replacements))}/
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
      errors.add(:body, _("Please sign at the bottom with your name, or alter the \"{{signoff}}\" signature", signoff: letter_template.signoff(default_message_replacements)))
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

    lines.compact.map { |line| line[/\w{6}-\w{6}-\w{2}/].strip }.compact
  end

  def exim_mail_server_logs
    logs = mta_ids.flat_map do |mta_id|
      info_request.
        mail_server_logs.
          where('line ILIKE :mta_id', mta_id: "%#{ mta_id }%")
    end

    smarthost_mta_ids = logs.flat_map do |log|
      line = log.line(decorate: true)
      if line.delivery_status.try(:delivered?)
        match = line.to_s.match(/C=".*?id=(?<message_id>\w+-\w+-\w+).*"/)
        match[:message_id] if match
      end
    end

    smarthost_mta_ids.compact!

    smarthost_logs = smarthost_mta_ids.flat_map do |mta_id|
      info_request.
        mail_server_logs.
          where('line ILIKE :mta_id', mta_id: "%#{ mta_id }%")
    end

    # Need to call #uniq because the more_logs query pulls out the initial
    # delivery line
    (logs + smarthost_logs).uniq
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
