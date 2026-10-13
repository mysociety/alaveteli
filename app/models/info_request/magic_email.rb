# Generate magic email and find an InfoRequest by the magic email
module InfoRequest::MagicEmail
  extend ActiveSupport::Concern

  included do
    before_validation :compute_idhash
  end

  class_methods do
    def magic_email_for_id(prefix_part, id)
      magic_email = AlaveteliConfiguration.incoming_email_prefix
      magic_email += prefix_part + id.to_s
      magic_email += "-" + InfoRequest.hash_from_id(id)
      magic_email += "@" + AlaveteliConfiguration.incoming_email_domain
      magic_email
    end

    def hash_from_id(id)
      Digest::SHA1.hexdigest(
        id.to_s + AlaveteliConfiguration.incoming_email_secret
      )[0, 8]
    end

    # Return info request corresponding to an incoming email address, or nil if
    # none found. Checks the hash to ensure the email came from the public
    # body - only they are sent the email address with the hash in it. (We don't
    # check the prefix and domain, as sometimes those change, or might be elided
    # by copying an email, and that doesn't matter)
    def find_by_incoming_email(incoming_email)
      id, hash = InfoRequest._extract_id_hash_from_email(incoming_email)
      if hash_from_id(id) == hash
        # Not using find(id) because we don't exception raised if nothing found
        find_by_id(id)
      end
    end

    # Public: Find by a list of incoming email addresses.
    # TODO: It would be better to make this return a chainable
    # ActiveRecord::Relation
    #
    # Examples:
    #
    #   InfoRequest.matching_incoming_email('request-1-ae63fb73@localhost')
    #   InfoRequest.matching_incoming_email(@array_of_email_addresses)
    #
    # Returns an Array
    def matching_incoming_email(emails)
      Array(emails).map { |email| find_by_incoming_email(email) }.compact
    end

    # Internal function used by find_by_incoming_email and
    # guess_by_incoming_email
    def _extract_id_hash_from_email(incoming_email)
      # Match case insensitively, FOI officers often write Request with a
      # capital R.
      incoming_email = incoming_email.downcase

      # The optional bounce- dates from when we used to have separate emails for
      # the envelope from.  (that was abandoned because councils would send hand
      # written responses to them, not just bounce messages)
      incoming_email =~ /request-(?:bounce-)?([a-z0-9]+)-([a-z0-9]+)/

      id = _id_string_to_i($1)
      hash = _clean_idhash($2)

      [id, hash]
    end

    # Internal function - attempts to convert a guessed id String from incoming
    # email addresses to an Integer. Returns nil if it fails to avoid
    # accidentally stripping trailing letters e.g. '123ab' should not match 123
    #
    # Returns an Integer
    def _id_string_to_i(id_string)
      Integer(id_string) if id_string
    rescue ArgumentError
      nil
    end

    # Internal function used to clean the id_hash from incoming email addresses.
    # Converts l to 1, and o to 0. FOI officers quite often retype the email
    # address and make this kind of error.
    def _clean_idhash(hash)
      return unless hash

      hash.gsub(/l/, "1").gsub(/o/, "0")
    end
  end

  # Email which public body should use to respond to request. This is in
  # the format PREFIXrequest-ID-HASH@DOMAIN. Here ID is the id of the
  # FOI request, and HASH is a signature for that id.
  def incoming_email
    magic_email("request-")
  end

  # Called by incoming_email - and used to be called to generate separate
  # envelope from address until we abandoned it.
  def magic_email(prefix_part)
    raise "id required to create a magic email" unless id

    InfoRequest.magic_email_for_id(prefix_part, id)
  end

  def compute_idhash
    self.idhash = InfoRequest.hash_from_id(id)
  end
end
