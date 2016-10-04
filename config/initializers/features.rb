# Initialize our store of feature flags using rollout
module Alaveteli
  module Features
    # Rollout assumes you'll use Redis for storing key:value pairs that
    # describe features and who can use them. For now we're storing this in an
    # ActiveRecord model instead for simplicity, so we configure Rollout to
    # use that instead.
    @@rollout = Rollout.new(RolloutKeyValueStore.new)

    # Wrap rollout's interface for checking if a feature is active
    def self.active?(feature, user = nil)
      @@rollout.active?(feature, user)
    end

    # Set up our available features and (optionally) get some defaults for
    # them from the config/general.yml configuration.
    # See https://github.com/fetlife/rollout for documentation on the options
    # available to you when activating/deactivating features.

    # List all of the available features here as constants so that we can
    # refer to them throughout the application consistently.
    ANNOTATIONS = :annotations
    FEATURES = [
      Alaveteli::Features::ANNOTATIONS,
    ].freeze

    # Annotations
    # We enable annotations based on the ENABLE_ANNOTATIONS config setting.
    # This isn't necessary, as we can activate or deactivate it at any time by
    # changing the value in the database, but since we've already exposed this
    # config value this maintains backward compatibility.
    if AlaveteliConfiguration.enable_annotations
      @@rollout.activate(Alaveteli::Features::ANNOTATIONS)
    else
      @@rollout.deactivate(Alaveteli::Features::ANNOTATIONS)
    end
  end
end