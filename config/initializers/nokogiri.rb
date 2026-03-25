module Nokogiri
  module Gumbo # :nodoc:
    silence_warnings do # prevent already initialized constant warnings
      ##
      # Increase the default depth Nokogiri will traverse. Need to increase
      # from the default value of 400 to correct handle some emails.
      #
      DEFAULT_MAX_TREE_DEPTH = 800
    end
  end
end
