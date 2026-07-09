# frozen_string_literal: true

require 'dry-validation'

class BulkExportContract < Dry::Validation::Contract
  params do
    optional(:limit).maybe(:integer)
    optional(:since).maybe(:string)
  end
end
