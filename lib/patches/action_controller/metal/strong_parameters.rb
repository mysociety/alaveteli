# frozen_string_literal: true

# rubocop:disable all
return unless rails_upgrade?

module ActionController
  class Parameters
    def encode_with(coder) # :nodoc:
      coder.map = { "parameters" => @parameters, "permitted" => @permitted }
    end
  end
end
