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
  end
end
