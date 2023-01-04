# == Schema Information
# Schema version: 20210114161442
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
          :inverse_of => :raw_email

  has_one_attached :file, service: :raw_emails

  before_destroy :destroy_file_representation!

  delegate :date, to: :mail
  delegate :message_id, to: :mail
  delegate :multipart?, to: :mail
  delegate :parts, to: :mail

  def addresses(include_invalid: false)
    MailHandler.get_all_addresses(mail, include_invalid: include_invalid)
  end

  # Return false if for some reason this is a message that we shouldn't let them
  # reply to
  #
  # TODO: Extract this validation out in to ReplyToAddressValidator#valid?
  def valid_to_reply_to?
    email = from_email.try(:downcase)

    # check validity of email
    return false if email.nil? || !MySociety::Validate.is_valid_email(email)

    # Check whether the email is a known invalid reply address
    if ReplyToAddressValidator.invalid_reply_addresses.include?(email)
      return false
    end

    prefix = email
    prefix =~ /^(.*)@/
    prefix = $1

    return false unless prefix

    no_reply_regexp = ReplyToAddressValidator.no_reply_regexp

    # reject postmaster - authorities seem to nearly always not respond to
    # email to postmaster, and it tends to only happen after delivery failure.
    # likewise Mailer-Daemon, Auto_Reply...
    return false if prefix.match(no_reply_regexp)
    return false if empty_return_path?
    return false if auto_submitted?
    true
  end

  def empty_from_field?
    mail.from_addrs.nil? || mail.from_addrs.size == 0
  end

  def mail
    @mail ||= mail!
  end

  def mail!
    @mail = MailHandler.mail_from_raw_email(data)
  end

  def data=(d)
    @data = d.to_s
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
    data.encode("UTF-8", :invalid => :replace,
                         :undef => :replace,
                         :replace => "")
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

  def destroy_file_representation!
    file.purge if file.attached?
  end
end
