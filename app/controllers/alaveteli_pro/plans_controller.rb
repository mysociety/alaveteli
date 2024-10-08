class AlaveteliPro::PlansController < AlaveteliPro::BaseController
  include AlaveteliPro::StripeNamespace

  skip_before_action :pro_user_authenticated?
  before_action :authenticate, :check_has_current_subscription, only: [:show]

  def index
    default_plan_name = add_stripe_namespace('pro')
    stripe_plan = Stripe::Plan.retrieve(default_plan_name)
    @plan = AlaveteliPro::Plan.new(stripe_plan)
    @pro_site_name = pro_site_name
  end

  def show
    stripe_plan = Stripe::Plan.retrieve(
      id: plan_name, expand: ['product']
    )
    @plan = AlaveteliPro::Plan.new(stripe_plan)
  rescue Stripe::InvalidRequestError
    raise ActiveRecord::RecordNotFound
  end

  private

  def plan_name
    add_stripe_namespace(params.require(:id))
  end

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
