##
# Module for caching email attributes from parsed mail content.
#
# It automatically caches attributes before saving and provides getter methods
# that ensure attributes are cached when accessed.
#
module RawEmail::CacheAttributes
  extend ActiveSupport::Concern

  included do
    before_save :cache_attributes_from_mail, if: :should_cache_attributes?
  end

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

  private

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
end
