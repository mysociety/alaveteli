require "alaveteli_features/version"
require "alaveteli_features/helpers"
require "alaveteli_features/constraints"
require "alaveteli_features/railtie" if defined?(Rails)
require "flipper"
require "flipper-active_record"

module AlaveteliFeatures
  def self.backend
    return @backend if @backend
    if self.tables_exist?
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

  # We just want to know if our tables exist, but we can't do that without
  # risking an error
  def self.tables_exist?
    begin
      ActiveRecord::Base.establish_connection
      return ActiveRecord::Base.connection.table_exists?(:flipper_features)
    rescue
      return false
    end
  end
end
