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

    cannot :receive, 'request_mailer#old_unclassified_updated' do
      last_status_update = info_request.info_request_events.
        where(event_type: 'status_update').
        last
      last_status_update.params[:project] if last_status_update
    end
  end

  private

  def info_request
    params[:info_request]
  end
end
