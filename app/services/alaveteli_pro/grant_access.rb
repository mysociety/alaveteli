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

    # enable the mail poller only if the POP polling is configured
    if AlaveteliConfiguration.production_mailer_retriever_method == 'pop'
      enable_actor(:accept_mail_from_poller, user)
    end

    enable_actor(:notifications, user)
    enable_actor(:pro_batch_access, user)
  end
end
