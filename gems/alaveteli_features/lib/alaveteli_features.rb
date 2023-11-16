require "alaveteli_features/version"
require "alaveteli_features/helpers"
require "alaveteli_features/constraints"
require "alaveteli_features/collection"
require "alaveteli_features/feature"
require "alaveteli_features/group"
require "alaveteli_features/railtie" if defined?(Rails)
require "flipper"
require "flipper-active_record" if defined?(Rails)

module AlaveteliFeatures
  def self.features
    @features ||= Collection.new(Feature)
  end

  def self.groups
    @groups ||= Collection.new(Group)
  end

  def self.backend
    return @backend if @backend

    if tables_exist?
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
    ActiveRecord::Base.establish_connection
    ActiveRecord::Base.connection.data_source_exists?(:flipper_features)
  rescue
    false
  end
end
