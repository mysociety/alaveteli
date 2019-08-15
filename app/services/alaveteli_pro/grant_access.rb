class AlaveteliPro::GrantAccess
  include AlaveteliFeatures::Helpers

  def self.call(*args, &block)
    new(*args, &block).call
  end

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def call
    user.add_role(:pro)

    # enable the mail poller only if the POP polling is configured AND it
    # has not already been enabled for this user (raises an error)
    if (AlaveteliConfiguration.production_mailer_retriever_method == 'pop' &&
        !feature_enabled?(:accept_mail_from_poller, user))
      AlaveteliFeatures.
        backend.
          enable_actor(:accept_mail_from_poller, user)
    end

    unless feature_enabled?(:notifications, user)
      AlaveteliFeatures.backend.enable_actor(:notifications, user)
    end

    unless feature_enabled?(:pro_batch_access, user)
      AlaveteliFeatures.backend.enable_actor(:pro_batch_access, user)
    end
  end
end
