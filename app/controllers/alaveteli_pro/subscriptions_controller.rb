# -*- encoding : utf-8 -*-
class AlaveteliPro::SubscriptionsController < AlaveteliPro::BaseController
  skip_before_action :pro_user_authenticated?, only: [:create]
  before_filter :authenticate, only: [:create]
  before_filter :check_existing_subscriptions, only: [:show]

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

      customer = current_user.pro_account.try(:stripe_customer)

      @customer =
        if customer
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

      subscription_attributes = {
        customer: @customer,
        plan: params[:plan_id],
        tax_percent: 20.0
      }

      coupon = params[:coupon_code]
      subscription_attributes[:coupon] = coupon.upcase if coupon.present?

      @subscription = Stripe::Subscription.create(subscription_attributes)

    rescue Stripe::CardError => e
      flash[:error] = e.message
      redirect_to plan_path(params[:plan_id])
      return

    rescue Stripe::RateLimitError,
           Stripe::InvalidRequestError,
           Stripe::AuthenticationError,
           Stripe::APIConnectionError,
           Stripe::StripeError => e

      if e.message =~ /No such coupon/
        flash[:notice] = _('Coupon code is invalid.')
      elsif e.message =~ /Coupon expired/
        flash[:notice] = _('Coupon code has expired.')
      else
        if send_exception_notifications?
          ExceptionNotifier.notify_exception(e, :env => request.env)
        end

        flash[:error] = _('There was a problem submitting your payment. You ' \
                          'have not been charged. Please try again later.')
      end

      path = params[:plan_id] ? plan_path(params[:plan_id]) : pro_plans_path
      redirect_to path
      return
    end

    current_user.add_role(:pro)

    flash[:notice] = _('Welcome to {{pro_site_name}}!',
                       pro_site_name: AlaveteliConfiguration.pro_site_name)
    redirect_to alaveteli_pro_dashboard_path
  end

  def show
    @customer = current_user.pro_account.try(:stripe_customer)
    @subscriptions = @customer.subscriptions.map do |subscription|
      AlaveteliPro::SubscriptionWithDiscount.new(subscription)
    end
    if @customer.default_source
      @card =
        @customer.
          sources.select { |card| card.id == @customer.default_source }.first
    end
  end

  def destroy
    begin
      @customer = current_user.pro_account.try(:stripe_customer)
      raise ActiveRecord::RecordNotFound unless @customer

      @subscription = Stripe::Subscription.retrieve(params[:id])

      unless @subscription.customer == @customer.id
        raise ActiveRecord::RecordNotFound
      end

      @subscription.delete(at_period_end: true)
    rescue Stripe::RateLimitError,
           Stripe::InvalidRequestError,
           Stripe::AuthenticationError,
           Stripe::APIConnectionError,
           Stripe::StripeError => e
      if send_exception_notifications?
        ExceptionNotifier.notify_exception(e, :env => request.env)
      end

      flash[:error] = _('There was a problem cancelling your account. Please ' \
                        'try again later.')

      redirect_to profile_subscription_path
      return
    end

    flash[:notice] = _('You have successfully cancelled your subscription ' \
                       'to {{pro_site_name}}',
                       pro_site_name: AlaveteliConfiguration.pro_site_name)

    redirect_to profile_subscription_path
  end

  private

  def authenticate
    post_redirect_params = {
      :web => _('To upgrade your account'),
      :email => _('Then you can upgrade your account'),
      :email_subject => _('To upgrade your account') }
    authenticated?(post_redirect_params)
  end

  def check_existing_subscriptions
    # TODO: This doesn't take the plan in to account
    unless @user.pro_account.try(:active?)
      flash[:notice] = _('You don\'t currently have an active Pro subscription')
      redirect_to pro_plans_path
    end
  end
end
