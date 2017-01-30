require "alaveteli_features/version"
require "alaveteli_features/helpers"
require "alaveteli_features/constraints"
require "alaveteli_features/railtie" if defined?(Rails)
require "flipper"
require "flipper-active_record"

module AlaveteliFeatures
  def self.backend
    return @backend if @backend
    if ActiveRecord::Base.connected? && \
       ActiveRecord::Base.connection.table_exists?(:flipper_features)
      @backend = Flipper.new(Flipper::Adapters::ActiveRecord.new)
    else
      if defined?(Rails)
        Rails.logger.warn "No database tables found for feature flags, you " \
                          "might need to set a backend explicitly if you " \
                          "don't want them stored in a database, or run" \
                          "rake db:migrate to create the table."
        Rails.logger.warn "Using memory-based feature storage instead."
      end
      require 'flipper/adapters/memory'
      @backend = Flipper.new(Flipper::Adapters::Memory.new)
    end
    @backend
  end

  # for overriding with memory adapter in tests
  def self.backend=(backend)
    @backend = backend
  end
end
