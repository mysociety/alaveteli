# -*- encoding : utf-8 -*-
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
          :inverse_of => :raw_email

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

  def directory
    if request_id.empty?
      raise "Failed to find the id number of the associated request: has it been saved?"
    end

    if Rails.env.test?
      File.join(Rails.root, 'files/raw_email_test')
    else
      File.join(AlaveteliConfiguration::raw_emails_location,
                request_id[0..2], request_id)
    end
  end

  def filepath
    if incoming_message_id.empty?
      raise "Failed to find the id number of the associated incoming message: has it been saved?"
    end

    File.join(directory, incoming_message_id)
  end

  def mail
    @mail ||= mail!
  end

  def mail!
    @mail = MailHandler.mail_from_raw_email(data)
  end

  def data=(d)
    FileUtils.mkdir_p(directory) unless File.exist?(directory)
    File.atomic_write(filepath) do |file|
      file.binmode
      file.write(d)
    end
  end

  def data
    File.open(filepath, "rb").read
  end

  def data_as_text
    text = data
    if text.respond_to?(:encoding)
      text = text.encode("UTF-8", :invalid => :replace,
                         :undef => :replace,
                         :replace => "")
    else
      text = Iconv.conv('UTF-8//IGNORE', 'UTF-8', text)
    end
    text
  end

  def destroy_file_representation!
    File.delete(filepath) if File.exist?(filepath)
  end

  def from_name
    MailHandler.get_from_name(mail)
  end

  def from_email
    MailHandler.get_from_address(mail)
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
end
