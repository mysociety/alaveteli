# Find the most likely InfoRequest when we don't have the exact id/idhash
module InfoRequest::Guessable
  extend ActiveSupport::Concern

  class_methods do
    # Public: Attempt to find InfoRequests by matching against extracted `id`
    # and `idhash` elements of an `incoming_email`.
    #
    # emails - A String email address or an Array of String email addresses.
    #
    # Returns an Array
    def guess_by_incoming_email(*emails)
      guesses = emails.flatten.reduce([]) do |memo, email|
        id, idhash = _extract_id_hash_from_email(email)
        id, idhash = _guess_idhash_from_email(email) if idhash.nil? || id.nil?

        memo << Guess.new(
          find_by_id(id), email: email, id: id, idhash: idhash
        )
        memo << Guess.new(
          find_by_idhash(idhash), email: email, id: id, idhash: idhash
        )
      end

      # Unique Guesses where we've found an `InfoRequest`
      guesses.select(&:info_request).uniq(&:info_request)
    end

    # Public: Attempt to find InfoRequests by matching against extracted `subject`
    # element of an `incoming_email`.
    #
    # subject_line - A String an email subject line
    # Returns an Array
    def guess_by_incoming_subject(subject_line)
      return [] unless subject_line

      # try to find a match on InfoRequest#title
      reply_format = InfoRequest.new(title: '').email_subject_followup
      requests_by_title = InfoRequest.left_joins(:incoming_messages).
        where(title: subject_line.gsub(/#{reply_format}/i, '').strip)

      # try to find a match on IncomingMessage#subject
      requests_by_subject = InfoRequest.left_joins(:incoming_messages).
        where(incoming_messages: {
                subject: [subject_line.gsub(/^Re: /i, ''), subject_line].uniq
              })

      requests = requests_by_title.or(requests_by_subject).
        distinct.
        where.not(url_title: 'holding_pen').
        limit(25)

      guesses = requests.each.reduce([]) do |memo, request|
        memo << Guess.new(request, subject: subject_line)
      end

      # Unique Guesses where we've found an `InfoRequest`
      guesses.select(&:info_request).uniq(&:info_request)
    end

    # Internal function used by guess_by_incoming_email
    def _guess_idhash_from_email(incoming_email)
      incoming_email = incoming_email.downcase
      incoming_email =~ /request\-?(\w+)-?(\w{8})@/

      id = _id_string_to_i(_clean_idhash($1))
      id_hash = $2

      if id_hash.nil? && incoming_email.include?('@')
        # try to grab the last 8 chars of the local part of the address instead
        local_part = incoming_email[0..incoming_email.index('@') - 1]
        id_hash =
          (_clean_idhash(local_part[-8..-1]) if local_part.length >= 8)
      end

      [id, id_hash]
    end
  end
end
