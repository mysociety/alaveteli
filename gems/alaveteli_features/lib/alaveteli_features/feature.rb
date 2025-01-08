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

        all_non_role_features.each do |feature|
          if keys.include?(feature.to_sym)
            feature.enable
          else
            feature.disable
          end
        end
      end

      def assign_role_features
        keys = role_features.map(&:to_sym)

        all_role_features.each do |feature|
          if keys.include?(feature.to_sym)
            feature.enable
          else
            feature.disable
          end
        end
      end

      private

      def all_non_role_features
        all.reject(&:roles?)
      end

      def all_role_features
        all.select(&:roles?)
      end

      def role_features
        raise ActorNotDefinedError unless actor

        select { |feature| (feature.roles & actor.roles).any? }
      end
    end

    attr_reader :key, :label, :condition, :actor
    attr_accessor :roles

    def initialize(key:, label: nil, condition: -> { true })
      @key = key
      @label = label || key
      @condition = condition
      @roles = []
    end

    def to_sym
      key.to_sym
    end

    def with_actor(actor)
      @actor = actor
      self
    end

    def roles?
      !roles.empty?
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
