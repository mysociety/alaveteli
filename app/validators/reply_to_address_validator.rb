# Public: Validates that we can reply to a ReplyTo address.
class ReplyToAddressValidator
  DEFAULT_NO_REPLY_REGEXP =
    /^(postmaster|mailer-daemon|auto_reply|do.?not.?reply|no.?reply)$/

  DEFAULT_INVALID_REPLY_ADDRESSES = [].freeze

  def self.no_reply_regexp
    @no_reply_regexp ||= DEFAULT_NO_REPLY_REGEXP
  end

  def self.no_reply_regexp=(regexp)
    @no_reply_regexp = Regexp.new(regexp)
  end

  def self.invalid_reply_addresses
    @invalid_reply_addresses ||= DEFAULT_INVALID_REPLY_ADDRESSES
  end

  def self.invalid_reply_addresses=(addresses)
    @invalid_reply_addresses = addresses.map(&:downcase)
  end

  def self.invalid_reply_address?(email_address)
    return false if email_address.blank?
    
    # Debug logging
    Rails.logger.info "DEBUG: Checking invalid reply address for: '#{email_address}'"
    Rails.logger.info "DEBUG: Database check result: #{InvalidReplyAddress.invalid?(email_address)}"
    Rails.logger.info "DEBUG: Manual config check result: #{invalid_reply_addresses.include?(email_address.downcase)}"
    
    # Check against database first
    return true if InvalidReplyAddress.invalid?(email_address)
    
    # Check against manually configured addresses (for backward compatibility)
    invalid_reply_addresses.include?(email_address.downcase)
  end
end
