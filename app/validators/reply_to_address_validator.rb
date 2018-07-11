# -*- encoding : utf-8 -*-
# Public: Validates that we can reply to a ReplyTo address.
class ReplyToAddressValidator
  DEFAULT_NO_REPLY_REGEXP =
    /^(postmaster|mailer-daemon|auto_reply|do.?not.?reply|no.?reply)$/.freeze

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
end
