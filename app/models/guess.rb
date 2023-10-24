require 'text'

##
# A guess at which info request a incoming message should be associated to
#
class Guess
  attr_reader :info_request, :components

  # The percentage similarity the id or idhash much fulfil
  THRESHOLD = 0.8

  ##
  # Return InfoRequest which we guess should receive an incoming message based
  # on a threshold.
  #
  def self.guessed_info_requests(email)
    # Match the email address in the message without matching the hash
    email_addresses = MailHandler.get_all_addresses(email)
    guesses = InfoRequest.guess_by_incoming_email(email_addresses)

    guesses_reaching_threshold = guesses.select do |ir_guess|
      id_score = ir_guess.id_score
      idhash_score = ir_guess.idhash_score

      (id_score == 1 && idhash_score >= THRESHOLD) ||
        (id_score >= THRESHOLD && idhash_score == 1)
    end

    guesses_reaching_threshold.map(&:info_request).uniq
  end

  def initialize(info_request, **components)
    @info_request = info_request
    @components = components
  end

  def [](key)
    components[key]
  end

  def id_score
    return 1 unless self[:id]
    similarity(self[:id], info_request.id)
  end

  def idhash_score
    return 1 unless self[:idhash]
    similarity(self[:idhash], info_request.idhash)
  end

  def ==(other)
    info_request == other.info_request && components == other.components
  end

  def match_method
    components.keys.first
  end

  private

  def similarity(a, b)
    Text::WhiteSimilarity.similarity(a.to_s, b.to_s)
  end
end
