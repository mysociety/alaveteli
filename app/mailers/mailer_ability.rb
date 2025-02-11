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

    cannot :receive, 'request_mailer#old_unclassified_updated' do
      info_request.created_at <= 6.months.ago
    end
  end

  private

  def info_request
    params[:info_request]
  end
end
