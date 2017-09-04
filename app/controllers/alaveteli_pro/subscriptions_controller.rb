# -*- encoding : utf-8 -*-
# Does not inherit from AlaveteliPro::BaseController as is pre-pro-login
class AlaveteliPro::SubscriptionsController < ApplicationController
  before_filter :authenticate

  # TODO: remove reminder of Stripe params once shipped
  #
  # params =>
  # {"utf8"=>"✓",
  #  "authenticity_token"=>"Ono2YgLcl1eC1gGzyd7Vf5HJJhOek31yFpT+8z+tKoo=",
  #  "stripeToken"=>"tok_s3kr3t…",
  #  "stripeTokenType"=>"card",
  #  "stripeEmail"=>"bob@example.com",
  #  "controller"=>"alaveteli_pro/subscriptions",
  #  "action"=>"create"}
  def create
    begin
      @token = Stripe::Token.retrieve(params[:stripeToken])

      existing_customer_id = current_user.pro_account.try(:stripe_customer_id)

      @customer =
        if existing_customer_id
          customer = Stripe::Customer.retrieve(existing_customer_id)
          customer.source = @token.id
          customer.save
          customer
        else
          customer =
            Stripe::Customer.create(email: params[:stripeEmail],
                                    source: @token)

          current_user.create_pro_account(stripe_customer_id: customer.id)
          customer
        end

      @subscription =
        Stripe::Subscription.create(customer: @customer,
                                    plan: params[:plan_id],
                                    tax_percent: 20.0)
    rescue Stripe::CardError => e
      flash[:error] = e.message
      redirect_to plan_path(params[:plan_id])
      return
    rescue Stripe::RateLimitError,
           Stripe::InvalidRequestError,
           Stripe::AuthenticationError,
           Stripe::APIConnectionError,
           Stripe::StripeError => e
      if send_exception_notifications?
        ExceptionNotifier.notify_exception(e, :env => request.env)
      end

      flash[:error] = _('There was a problem submitting your payment. You ' \
                        'have not been charged. Please try again later.')

      path = params[:plan_id] ? plan_path(params[:plan_id]) : plans_path
      redirect_to path
      return
    end

    current_user.add_role(:pro)

    flash[:notice] = _('Welcome to {{pro_site_name}}!',
                       pro_site_name: AlaveteliConfiguration.pro_site_name)
    redirect_to alaveteli_pro_dashboard_path
  end

  def show
    @customer = Stripe::Customer.
                  retrieve(current_user.pro_account.stripe_customer_id)
  end

  private

  def authenticate
    if action_name == "index"
      post_redirect_params = {
        :web => _('To upgrade your account'),
        :email => _('To upgrade your account'),
        :email_subject => _('To upgrade your account') }
    else
      post_redirect_params = {
        :web => _('To access your account'),
        :email => _('To access your account'),
        :email_subject => _('To access your account') }
    end
    authenticated?(post_redirect_params)
  end
end
