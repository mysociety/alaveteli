# -*- encoding : utf-8 -*-
class AlaveteliPro::PlansController < AlaveteliPro::BaseController
  include AlaveteliPro::StripeNamespace

  skip_before_action :pro_user_authenticated?
  before_filter :authenticate, :check_existing_subscription, only: [:show]

  def index
  end

  def show
    stripe_plan = Stripe::Plan.retrieve(plan_name)
    @plan = AlaveteliPro::WithTax.new(stripe_plan)
    @stripe_button_description = stripe_button_description(@plan.interval)
  rescue Stripe::InvalidRequestError
    raise ActiveRecord::RecordNotFound
  end

  private

  def plan_name
    add_stripe_namespace(params.require(:id))
  end

  def stripe_button_description(interval)
    case interval
    when 'month'
      _('A monthly subscription')
    when 'year'
      _('An annual subscription')
    end
  end

  def authenticate
    post_redirect_params = {
      web: _('To signup to {{site_name}}',
             site_name: AlaveteliConfiguration.pro_site_name),
      email: _('Then you can activate your {{site_name}} account',
               site_name: AlaveteliConfiguration.pro_site_name),
      email_subject: _('Confirm your account on {{site_name}}',
                       site_name: AlaveteliConfiguration.pro_site_name) }

    pro_authenticated?(post_redirect_params)
  end

  def check_existing_subscription
    # TODO: This doesn't take the plan in to account
    if @user.pro_account.try(:active?)
      flash[:error] = _('You are already subscribed to this plan')
      redirect_to subscriptions_path
    end
  end
end
