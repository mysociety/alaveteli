##
# A service object to grant and revoke users access to Alaveteli Professional
# features
#
# Usage:
#   AlaveteliPro::Access.grant(user)
#
# TODO:
#   AlaveteliPro::Access.revoke(user)
#
class AlaveteliPro::Access
  include AlaveteliFeatures::Helpers

  def self.grant(*args, &block)
    new(*args, &block).grant
  end

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def grant
    # enable the mail poller only if the POP polling is configured
    if AlaveteliConfiguration.production_mailer_retriever_method == 'pop'
      enable_actor(:accept_mail_from_poller, user)
    end

    enable_actor(:notifications, user)
  end
end
