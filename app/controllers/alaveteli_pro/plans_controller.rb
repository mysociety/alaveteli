class AlaveteliPro::PlansController < AlaveteliPro::BaseController
  skip_before_action :pro_user_authenticated?
  before_action :authenticate, :check_has_current_subscription, only: [:show]

  def index
    @prices = AlaveteliPro::Price.list
    @pro_site_name = pro_site_name
  end

  def show
    @price = AlaveteliPro::Price.retrieve(params[:id])
    @price || raise(ActiveRecord::RecordNotFound)
  end

  private

  def authenticate
    authenticated? || ask_to_login(
      pro: true,
      web: _('To signup to {{site_name}}',
             site_name: pro_site_name),
      email: _('Then you can activate your {{site_name}} account',
               site_name: pro_site_name),
      email_subject: _('Confirm your account on {{site_name}}',
                       site_name: pro_site_name)
    )
  end

  def check_has_current_subscription
    # TODO: This doesn't take the plan in to account
    return unless @user.pro_account.try(:subscription?)

    flash[:error] = _('You are already subscribed to this plan')
    redirect_to subscriptions_path
  end
end
