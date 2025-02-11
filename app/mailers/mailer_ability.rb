##
# This ability model enforces permission rules for mailer functions.
#
class MailerAbility
  include CanCan::Ability

  attr_reader :user, :params

  def initialize(user, **params)
    @user = user
    @params = params

    can :receive, :all
  end
end
