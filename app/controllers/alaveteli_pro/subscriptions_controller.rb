# -*- encoding : utf-8 -*-
class AlaveteliPro::SubscriptionsController < AlaveteliPro::BaseController
  include AlaveteliPro::StripeNamespace

  skip_before_action :pro_user_authenticated?, only: [:create]
  before_action :authenticate, :prevent_duplicate_submission, only: [:create]
  before_action :check_plan_exists, only: [:create]
  before_action :check_active_subscription, only: [:index]

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
  #  "stripe_token"=>"tok_s3kr3t…",
  #  "controller"=>"alaveteli_pro/subscriptions",
  #  "action"=>"create",
  #  "plan_id"=>"WDTK-pro"}
  def create
    begin
      @token = Stripe::Token.retrieve(params[:stripe_token])

      @pro_account = current_user.pro_account ||= current_user.build_pro_account
      @pro_account.source = @token.id
      @pro_account.update_stripe_customer

      subscription_attributes = {
        customer: @pro_account.stripe_customer,
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

      redirect_to plan_path(non_namespaced_plan_id)
      return
    end

    AlaveteliPro::GrantAccess.call(current_user)

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
    remove_stripe_namespace(params[:plan_id]) if params[:plan_id]
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

  def check_plan_exists
    redirect_to(pro_plans_path) unless non_namespaced_plan_id
  end

  def prevent_duplicate_submission
    # TODO: This doesn't take the plan in to account
    if @user.pro_account.try(:active?)
      redirect_to alaveteli_pro_dashboard_path
    end
  end
end
