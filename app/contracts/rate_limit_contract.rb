# frozen_string_literal: true

require 'dry-validation'

class RateLimitContract < Dry::Validation::Contract
  params do
    optional(:ip).filled(:string)
  end
end
