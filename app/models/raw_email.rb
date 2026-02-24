# == Schema Information
#
# Table name: raw_emails
#
#  id               :integer          not null, primary key
#  created_at       :datetime
#  updated_at       :datetime
#  erased_at        :datetime
#  message_id       :string
#  message_checksum :string
#

# models/raw_email.rb:
# The fat part of models/incoming_message.rb
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class RawEmail < ApplicationRecord
  class AlreadyErasedError < StandardError; end
  class UnmaskedAttachmentsError < StandardError; end

  # deliberately don't strip_attributes, so keeps raw email properly

  has_one :incoming_message,
          inverse_of: :raw_email

  has_one :info_request, through: :incoming_message

  has_one_attached :file, service: :raw_emails

  delegate :date, to: :mail
  delegate :multipart?, to: :mail
  delegate :parts, to: :mail

  delegate :expire, :log_event, to: :info_request

  delegate :lock_all_attachments, to: :incoming_message
  delegate :all_attachments_masked?, to: :incoming_message

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

  def mail=(new_mail)
    @data = new_mail.raw_source # If mail library is passed a string
    @data = new_mail.encoded if @data.empty? # or if built using the DSL

    file.attach(
      io: StringIO.new(@data),
      filename: "#{incoming_message_id}.eml",
      content_type: 'message/rfc822'
    )
  end

  def mail
    @mail ||= mail!
  end

  def mail!
    @mail = Mail.from_source(data)
  end

  def data=(new_data)
    new_mail = new_data if new_data.is_a?(Mail::Message)
    new_mail ||= (
      new_data.force_encoding(Encoding::BINARY)
      Mail.new(new_data)
    )

    self.mail = new_mail
  end

  def data
    @data ||= file.download if file.attached?
  end

  def data_as_text
    data&.encode('UTF-8', invalid: :replace,
                          undef: :replace,
                          replace: '')
  end

  def erased?
    !file.attached? && erased_at.present?
  end

  def erasable?
    all_attachments_masked?
  end

  def erase(editor:, reason:)
    raise AlreadyErasedError if erased?
    raise UnmaskedAttachmentsError unless all_attachments_masked?

    transaction do |t|
      t.after_rollback { return false }

      raise ActiveRecord::Rollback unless
        lock_all_attachments(
          editor: editor,
          reason: 'RawEmail#erase',
          raw_email: self
        )

      raise ActiveRecord::Rollback unless
        log_event(
          'erase_raw_email',
          editor: editor,
          reason: reason,
          raw_email: self,
          storage_key: storage_key
        )

      file.purge_later
      touch(:erased_at)

      expire(preserve_database_cache: true)

      true
    end
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

  def message_id
    return self[:message_id] if self[:message_id].present?

    # taken from https://github.com/rails/rails/blob/624fe3c/actionmailbox/app/models/action_mailbox/inbound_email/message_id.rb#L27-L35
    message_id = mail.message_id rescue nil
    message_id ||= Mail::MessageIdField.new(
      "<#{message_checksum}@#{::Socket.gethostname}.mail>"
    ).message_id

    update_column(:message_id, message_id)
    message_id
  end

  def message_checksum
    return self[:message_checksum] if self[:message_checksum].present?

    # taken from https://github.com/rails/rails/blob/624fe3c/actionmailbox/app/models/action_mailbox/inbound_email/message_id.rb#L17
    message_checksum = OpenSSL::Digest::SHA1.hexdigest(data)

    update_column(:message_checksum, message_checksum)
    message_checksum
  end

  private

  def empty_return_path?
    MailHandler.empty_return_path?(mail)
  end

  def auto_submitted?
    MailHandler.get_auto_submitted(mail)
  end

  def request_id
    info_request.id.to_s
  end

  def incoming_message_id
    incoming_message.id.to_s
  end
end
