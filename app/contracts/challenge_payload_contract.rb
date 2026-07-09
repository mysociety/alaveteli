# frozen_string_literal: true

require 'dry-validation'

class ChallengePayloadContract < Dry::Validation::Contract
  params do
    required(:cf_turnstile_response).filled(:string)
  end
end
