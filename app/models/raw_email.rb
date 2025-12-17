# == Schema Information
#
# Table name: raw_emails
#
#  id         :integer          not null, primary key
#  created_at :datetime
#  updated_at :datetime
#

# models/raw_email.rb:
# The fat part of models/incoming_message.rb
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class RawEmail < ApplicationRecord
  # deliberately don't strip_attributes, so keeps raw email properly

  has_one :incoming_message,
          inverse_of: :raw_email

  has_one_attached :file, service: :raw_emails

  delegate :date, to: :mail
  delegate :message_id, to: :mail
  delegate :multipart?, to: :mail
  delegate :parts, to: :mail

  def addresses(include_invalid: false)
    MailHandler.get_all_addresses(mail, include_invalid: include_invalid)
  end

  def valid_to_reply_to?
    ReplyToAddressValidator.valid?(from_email) &&
      !empty_return_path? &&
      !auto_submitted?
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

    file.attach(
      io: StringIO.new(@data),
      filename: "#{incoming_message_id}.eml",
      content_type: 'message/rfc822'
    )
  end

  def data
    @data ||= file.download if file.attached?
  end

  def data_as_text
    data.encode("UTF-8", invalid: :replace,
                         undef: :replace,
                         replace: "")
  end

  def from_name
    MailHandler.get_from_name(mail)
  end

  def from_email
    MailHandler.get_from_address(mail)
  end

  def from_email_domain
    PublicBody.extract_domain_from_email(from_email)
  end

  def subject
    MailHandler.get_subject(mail)
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
