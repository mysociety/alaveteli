# -*- encoding : utf-8 -*-
class AlaveteliPro::SubscriptionsController < AlaveteliPro::BaseController
  include AlaveteliPro::StripeNamespace

  skip_before_action :pro_user_authenticated?, only: [:create]
  before_filter :authenticate, :prevent_duplicate_submission, only: [:create]
  before_filter :check_active_subscription, only: [:index]

  def index
    @customer = current_user.pro_account.try(:stripe_customer)
    @subscriptions = @customer.subscriptions.map do |subscription|
      AlaveteliPro::SubscriptionWithDiscount.new(subscription)
    end
    if @customer.default_source
      @card =
        @customer.
          sources.select { |card| card.id == @customer.default_source }.first
    end

    if referral_coupon
      @discount_code = remove_stripe_namespace(referral_coupon.id)
      @discount_terms = referral_coupon.metadata.humanized_terms
    end
  end

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

      subscription_attributes[:coupon] = coupon_code if coupon_code?

      @subscription = Stripe::Subscription.create(subscription_attributes)

    rescue Stripe::CardError => e
      flash[:error] = e.message
      redirect_to plan_path(non_namespaced_plan_id)
      return

    rescue Stripe::RateLimitError,
           Stripe::InvalidRequestError,
           Stripe::AuthenticationError,
           Stripe::APIConnectionError,
           Stripe::StripeError => e

      flash[:error] =
        case e.message
        when /No such coupon/
          _('Coupon code is invalid.')
        when /Coupon expired/
          _('Coupon code has expired.')
        else
          if send_exception_notifications?
            ExceptionNotifier.notify_exception(e, :env => request.env)
          end

          _('There was a problem submitting your payment. You ' \
            'have not been charged. Please try again later.')
        end

      if params[:plan_id]
        redirect_to plan_path(non_namespaced_plan_id)
      else
        redirect_to pro_plans_path
      end
      return
    end

    current_user.add_role(:pro)

    # enable the mail poller only if the POP polling is configured AND it
    # has not already been enabled for this user (raises an error)
    if (AlaveteliConfiguration.production_mailer_retriever_method == 'pop' &&
        !feature_enabled?(:accept_mail_from_poller, current_user))
      AlaveteliFeatures.
        backend.
          enable_actor(:accept_mail_from_poller, current_user)
    end

    unless feature_enabled?(:notifications, current_user)
      AlaveteliFeatures.backend.enable_actor(:notifications, current_user)
    end

    unless feature_enabled?(:pro_batch_access, current_user)
      AlaveteliFeatures.backend.enable_actor(:pro_batch_access, current_user)
    end

    flash[:notice] =
      { :partial => "alaveteli_pro/subscriptions/signup_message.html.erb" }
    flash[:new_pro_user] = true
    redirect_to alaveteli_pro_dashboard_path
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

      flash[:notice] = _('You have successfully cancelled your subscription ' \
                         'to {{pro_site_name}}',
                         pro_site_name: AlaveteliConfiguration.pro_site_name)

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
    end

    redirect_to subscriptions_path
  end

  private

  def authenticate
    post_redirect_params = {
      :web => _('To upgrade your account'),
      :email => _('Then you can upgrade your account'),
      :email_subject => _('To upgrade your account') }
    authenticated?(post_redirect_params)
  end

  def check_active_subscription
    # TODO: This doesn't take the plan in to account
    unless @user.pro_account.try(:active?)
      flash[:notice] = _('You don\'t currently have an active Pro subscription')
      redirect_to pro_plans_path
    end
  end

  def non_namespaced_plan_id
    remove_stripe_namespace(params[:plan_id])
  end

  def coupon_code?
    params[:coupon_code].present?
  end

  def coupon_code
    add_stripe_namespace(params.require(:coupon_code)).upcase
  end

  def referral_coupon
    coupon_code =
      add_stripe_namespace(AlaveteliConfiguration.pro_referral_coupon)

    @referral_coupon ||=
      unless coupon_code.blank?
        begin
          Stripe::Coupon.retrieve(coupon_code)
        rescue Stripe::StripeError
        end
      end
  end

  def prevent_duplicate_submission
    # TODO: This doesn't take the plan in to account
    if @user.pro_account.try(:active?)
      redirect_to alaveteli_pro_dashboard_path
    end
  end
end
