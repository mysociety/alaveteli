# Handle the parsing and caching of the associated RawEmail
module IncomingMessage::FromRawEmail
  extend ActiveSupport::Concern

  included do
    belongs_to :raw_email, inverse_of: :incoming_message, dependent: :destroy

    scope :unparsed, -> { where(last_parsed: nil) }

    delegate :message_id, to: :raw_email
    delegate :multipart?, to: :raw_email
    delegate :parts, to: :raw_email

    cache_from_raw_email :subject, :sent_at,
                         :from_name, :from_email, :from_email_domain,
                         :valid_to_reply_to
  end

  class_methods do
    def cache_from_raw_email(*attrs)
      attrs.each { |attr| cache_attribute_from_raw_email(attr) }
    end

    def cache_attribute_from_raw_email(attr)
      define_method(attr) do
        parse_raw_email
        super()
      end
    end
  end

  def parse_raw_email
    raise "Incoming message id=#{id} has no raw_email" if raw_email.nil?

    parse_raw_email! if last_parsed.nil?
  end

  # refreshes the incoming message metadata from the raw email
  # Does NOT refresh the body of the message (use clear_in_database_caches!)
  def parse_raw_email!
    # The following fields may be absent; we treat them as cached
    # values in case we want to regenerate them (due to mail
    # parsing bugs, etc).
    raise "Incoming message id=#{id} has no raw_email" if raw_email.nil?

    raw_email_ensure_not_erased!

    ActiveRecord::Base.transaction do
      # Lock the row to serialize concurrent re-parsing, otherwise two
      # processes can each insert a full set of attachments. Locking a
      # fresh copy avoids reloading self mid-parse.
      self.class.lock.find(id) if persisted?

      extract_attachments
      self.sent_at = raw_email.date || created_at
      self.subject = raw_email.subject
      self.from_name = raw_email.from_name
      self.from_email = raw_email.from_email || ''
      self.from_email_domain = raw_email.from_email_domain || ''
      self.valid_to_reply_to = raw_email.valid_to_reply_to?
      self.last_parsed = Time.zone.now
      save!
    end
  end
end
