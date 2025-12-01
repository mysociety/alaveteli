# == Schema Information
#
# Table name: raw_emails
#
#  id                :integer          not null, primary key
#  created_at        :datetime
#  updated_at        :datetime
#  from_email        :text
#  from_email_domain :text
#  from_name         :text
#  message_id        :text
#  sent_at           :datetime
#  subject           :text
#  valid_to_reply_to :boolean
#

# models/raw_email.rb:
# The fat part of models/incoming_message.rb
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class RawEmail < ApplicationRecord
  # deliberately don't strip_attributes, so keeps raw email properly

  CACHED_ATTRIBUTES = %i[
    from_email from_email_domain from_name message_id sent_at subject
    valid_to_reply_to
  ].freeze

  has_one :incoming_message,
          inverse_of: :raw_email

  has_one_attached :file, service: :raw_emails

  before_save :cache_attributes, if: :cache_attributes?

  # TODO: to remove
  delegate :date, to: :mail
  delegate :message_id, to: :mail
  # ----
  delegate :multipart?, to: :mail
  delegate :parts, to: :mail

  CACHED_ATTRIBUTES.each do |attr|
    define_method attr do
      value = super()
      # TODO: Don't cache empty strings
      value = send("parse_#{attr}") if value.nil? || value == ''
      value
    end
  end

  alias valid_to_reply_to? valid_to_reply_to

  def addresses(include_invalid: false)
    MailHandler.get_all_addresses(mail, include_invalid: include_invalid)
  end

  def empty_from_field?
    mail.from_addrs.nil? || mail.from_addrs.empty?
  end

  def mail
    @mail ||= mail!
  end

  def mail!
    @mail = MailHandler.mail_from_string(data)
  end

  def data=(d)
    @data = d.to_s
    @mail = nil
    clear_cached_attributes

    file.attach(
      io: StringIO.new(@data),
      filename: "#{incoming_message_id}.eml",
      content_type: 'message/rfc822'
    )

    @data
  end

  def data
    @data ||= file.download if file.attached?
  end

  def data_as_text
    data.encode("UTF-8", invalid: :replace,
                         undef: :replace,
                         replace: "")
  end

  def storage_key
    file.blob.key if file&.attached?
  end

  def reload(*)
    @data = nil
    @mail = nil
    super
  end

  private

  def cache_attributes?
    file.attached? && read_attribute(:message_id).blank?
  end

  def cache_attributes
    attrs = CACHED_ATTRIBUTES.each_with_object({}) do |attr, memo|
      memo[attr] = send("parse_#{attr}")
    end

    assign_attributes(attrs)
  end

  def clear_cached_attributes
    CACHED_ATTRIBUTES.each { |attr| write_attribute(attr, nil) }
  end

  def parse_from_name
    MailHandler.get_from_name(mail)
  end

  def parse_from_email
    MailHandler.get_from_address(mail) || ''
  end

  def parse_from_email_domain
    PublicBody.extract_domain_from_email(from_email) || ''
  end

  def parse_subject
    MailHandler.get_subject(mail)
  end

  def parse_sent_at
    mail.date || created_at
  end

  def parse_message_id
    mail.message_id
  end

  def parse_valid_to_reply_to
    ReplyToAddressValidator.valid?(from_email) &&
      !empty_return_path? &&
      !auto_submitted?
  end

  def empty_return_path?
    MailHandler.empty_return_path?(mail)
  end

  def auto_submitted?
    MailHandler.get_auto_submitted(mail)
  end

  def request_id
    incoming_message.info_request.id.to_s
  end

  def incoming_message_id
    incoming_message.id.to_s
  end
end
