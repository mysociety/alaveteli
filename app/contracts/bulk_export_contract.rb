# frozen_string_literal: true

require 'dry-validation'

class BulkExportContract < Dry::Validation::Contract
  params do
    optional(:limit).maybe(:integer)
    optional(:since).maybe(:string)
  end

  rule(:limit) do
    key.failure('must be greater than 0') if value && value <= 0
  end

  rule(:since) do
    next if value.blank?

    key.failure('must be a valid timestamp') unless Time.zone.parse(value)
  rescue ArgumentError
    key.failure('must be a valid timestamp')
  end
end
