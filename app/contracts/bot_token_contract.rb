# frozen_string_literal: true

require 'dry-validation'

class BotTokenContract < Dry::Validation::Contract
  params do
    required(:token).filled(:string)
    optional(:bot_name).maybe(:string)
  end
end
