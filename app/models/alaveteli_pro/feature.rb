module AlaveteliPro
  ##
  # Wrapper class for checking and updating Pro feature flags for Pro users
  #
  class Feature
    include AlaveteliFeatures::Helpers

    FEATURES = [
      {
        key: :accept_mail_from_poller,
        label: 'Receive response via the POP poller'
      },
      { key: :notifications, label: 'Daily email notification digests' },
      { key: :pro_batch_category_ui, label: 'Batch category user interface' }
    ].freeze

    class << self
      def all
        FEATURES.map { |feature| new(**feature) }
      end

      def with_user(user)
        all.map { |feature| feature.with_user(user) }
      end

      def enable_user_features(user:, extra_features: [])
        extra_features = extra_features.map(&:to_sym)

        with_user(user).each do |feature|
          if extra_features.include?(feature.key)
            feature.enable
          else
            feature.disable
          end
        end
      end
    end

    NoUserDefinedError = Class.new(StandardError)

    attr_reader :key, :label

    def initialize(key:, label:)
      @key = key
      @label = label
    end

    def with_user(user)
      @user = user
      self
    end

    def enabled?
      raise NoUserDefinedError unless @user
      feature_enabled?(key, @user)
    end

    def enable
      raise NoUserDefinedError unless @user
      enable_actor(key, @user)
    end

    def disable
      raise NoUserDefinedError unless @user
      disable_actor(key, @user)
    end
  end
end
