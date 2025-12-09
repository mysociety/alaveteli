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

  before_save :cache_attributes_from_mail, if: :should_cache_attributes?

  cached_columns = %i[
    from_email from_email_domain from_name message_id sent_at subject
    valid_to_reply_to
  ].freeze

  cached_columns.each do |method|
    define_method method do
      cache_attributes_from_mail if should_cache_attributes?
      read_attribute(method)
    end
  end

  alias valid_to_reply_to? valid_to_reply_to

  def cache_attributes_from_mail
    return unless file.attached?

    from_email = MailHandler.get_from_address(mail) || ''

    assign_attributes(
      subject: MailHandler.get_subject(mail),
      sent_at: mail.date || created_at,
      from_name: MailHandler.get_from_name(mail),
      from_email: from_email,
      message_id: mail.message_id,
      from_email_domain: PublicBody.extract_domain_from_email(from_email) || '',
      valid_to_reply_to: ReplyToAddressValidator.valid?(from_email) &&
        !empty_return_path? && !auto_submitted?
    )
  end

  def should_cache_attributes?
    file.attached? && read_attribute(:message_id).blank?
  end

  has_one :incoming_message,
          inverse_of: :raw_email

  has_one_attached :file, service: :raw_emails

  delegate :multipart?, to: :mail
  delegate :parts, to: :mail

  def addresses(include_invalid: false)
    MailHandler.get_all_addresses(mail, include_invalid: include_invalid)
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
    data.encode("UTF-8", invalid: :replace,
                         undef: :replace,
                         replace: "")
  end

  def storage_key
    file.blob.key if file&.attached?
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
