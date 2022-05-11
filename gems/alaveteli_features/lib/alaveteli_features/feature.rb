module AlaveteliFeatures
  ##
  # A feature class which allows checking if a feature is enabled for a actor
  #
  class Feature
    include Helpers

    ActorNotDefinedError = Class.new(StandardError)

    ##
    # Methods to extend a Collection object of features to query
    #
    module CollectionMethods
      attr_reader :actor

      def with_actor(actor)
        @actor = actor
        each { |feature| feature.with_actor(actor) }
        self
      end

      def enabled?(key)
        all.find { |f| f.key == key }&.enabled? || false
      end
    end

    attr_reader :key, :label, :actor

    def initialize(key:, label: nil)
      @key = key
      @label = label || key
    end

    def to_sym
      key.to_sym
    end

    def with_actor(actor)
      @actor = actor
      self
    end

    def enabled?
      raise ActorNotDefinedError unless actor
      feature_enabled?(key, actor)
    end

    def disabled?
      !enabled?
    end
  end
end
