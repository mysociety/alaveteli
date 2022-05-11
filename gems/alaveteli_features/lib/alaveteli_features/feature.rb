module AlaveteliFeatures
  ##
  # A feature class which allows checking if a feature is enabled for a actor
  # and toggling features on and off
  #
  class Feature
    include Helpers

    ActorNotDefinedError = Class.new(StandardError)

    ##
    # Methods to extend a Collection object of features to query and assign
    # features for a given actor
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

      def assign_features(new_features)
        keys = new_features.map(&:to_sym)

        all.each do |feature|
          if keys.include?(feature.to_sym)
            feature.enable
          else
            feature.disable
          end
        end
      end
    end

    attr_reader :key, :label, :condition, :actor

    def initialize(key:, label: nil, condition: -> { true })
      @key = key
      @label = label || key
      @condition = condition
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
      feature_enabled?(key, actor) && condition.call
    end

    def disabled?
      !enabled?
    end

    def enable
      raise ActorNotDefinedError unless actor
      enable_actor(key, actor)
    end

    def disable
      raise ActorNotDefinedError unless actor
      disable_actor(key, actor)
    end
  end
end
