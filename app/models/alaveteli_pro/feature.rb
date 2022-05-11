module AlaveteliPro
  ##
  # Wrapper class for checking and updating Pro feature flags for Pro users
  #
  class Feature
    include AlaveteliFeatures::Helpers

    FEATURES = [
      {
        key: :accept_mail_from_poller,
        label: 'Receive response via the POP poller',
        condition: -> {
          AlaveteliConfiguration.production_mailer_retriever_method == 'pop'
        }
      },
      { key: :notifications, label: 'Daily email notification digests' },
      { key: :pro_batch_category_ui, label: 'Batch category user interface' }
    ].freeze

    FEATURE_GROUPS = {
      base: { features: %i[accept_mail_from_poller notifications] },
      beta: { include: :base, features: %i[pro_batch_category_ui] }
    }.freeze

    ROLE_FEATURE_GROUP = {
      pro: :base
    }.freeze

    class << self
      def all
        FEATURES.map { |feature| new(**feature) }
      end

      def with_user(user)
        all.map { |feature| feature.with_user(user) }
      end

      def enable_user_role_features(user:, extra_features: [])
        all_features = user_role_features(user) + extra_features.map(&:to_sym)
        all_features.uniq!

        with_user(user).each do |feature|
          if all_features.include?(feature.key)
            feature.enable
          else
            feature.disable
          end
        end
      end

      def feature_roles(feature:)
        ROLE_FEATURE_GROUP.inject([]) do |memo, (role, group)|
          memo << role if group_features(group).include?(feature)
          memo
        end
      end

      private

      def user_roles(user)
        user.roles.map { |r| r.name.to_sym }
      end

      def user_role_features(user)
        user_roles(user).inject([]) do |memo, r|
          memo += group_features(ROLE_FEATURE_GROUP[r])
          memo.uniq
        end
      end

      def group_features(group)
        feature_group = FEATURE_GROUPS.fetch(group, { features: [] })
        parent_group = feature_group[:include]

        features = feature_group[:features]
        features += group_features(parent_group) if parent_group
        features.uniq
      end
    end

    NoUserDefinedError = Class.new(StandardError)

    attr_reader :key, :label, :condition

    def initialize(key:, label:, condition: -> { true })
      @key = key
      @label = label
      @condition = condition
    end

    def to_sym
      key.to_sym
    end

    def with_user(user)
      @user = user
      self
    end

    def roles
      self.class.feature_roles(feature: key)
    end

    def extra?
      roles.empty?
    end

    def role_feature_or_disabled?
      raise NoUserDefinedError unless @user
      !(extra? && condition.call)
    end

    def enabled?
      raise NoUserDefinedError unless @user
      feature_enabled?(key, @user) && condition.call
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
