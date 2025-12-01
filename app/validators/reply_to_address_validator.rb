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

  # Return false if for some reason this is a message that we shouldn't let them
  # reply to
  def self.valid?(from_email)
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

    true
  end
end
