# -*- encoding : utf-8 -*-
class AlaveteliPro::SubscriptionsController < AlaveteliPro::BaseController
  include AlaveteliPro::StripeNamespace

  skip_before_action :pro_user_authenticated?, only: [:create, :authorise]
  before_action :authenticate, only: [:create, :authorise]
  before_action :prevent_duplicate_submission, only: [:create]
  before_action :check_plan_exists, only: [:create]
  before_action :check_has_current_subscription, only: [:index]

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
      @pro_account = current_user.pro_account ||= current_user.build_pro_account

      # Ensure previous incomplete subscriptions are cancelled to prevent them
      # from using the new card
      @pro_account.subscriptions.incomplete.map(&:delete)

      @token = Stripe::Token.retrieve(params[:stripe_token])

      @pro_account.source = @token.id
      @pro_account.update_stripe_customer

      @subscription = @pro_account.subscriptions.build
      @subscription.update_attributes(
        plan: params.require(:plan_id),
        tax_percent: tax_percent,
        payment_behavior: 'allow_incomplete'
      )

      @subscription.coupon = coupon_code if coupon_code?

      @subscription.save

    rescue Stripe::CardError => e
      flash[:error] = e.message

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
    end

    if flash[:error]
      json_redirect_to plan_path(non_namespaced_plan_id)
    else
      redirect_to authorise_subscription_path(@subscription.id)
    end
  end

  def authorise
    begin
      @subscription = current_user.pro_account.subscriptions.
        retrieve(params.require(:id))

      if !@subscription
        head :not_found

      elsif @subscription.require_authorisation?
        respond_to do |format|
          format.json do
            render json: {
              payment_intent: @subscription.payment_intent.client_secret,
              callback_url: authorise_subscription_path(@subscription.id)
            }
          end
        end

      elsif @subscription.invoice_open?
        flash[:error] = _('There was a problem authorising your payment. You ' \
                          'have not been charged. Please try again.')

        json_redirect_to plan_path(
          remove_stripe_namespace(@subscription.plan.id)
        )

      elsif @subscription.active?
        current_user.add_role(:pro)

        flash[:notice] = {
          partial: 'alaveteli_pro/subscriptions/signup_message.html.erb'
        }
        flash[:new_pro_user] = true

        json_redirect_to alaveteli_pro_dashboard_path

      else
        head :ok
      end

    rescue Stripe::RateLimitError,
           Stripe::InvalidRequestError,
           Stripe::AuthenticationError,
           Stripe::APIConnectionError,
           Stripe::StripeError => e
      if send_exception_notifications?
        ExceptionNotifier.notify_exception(e, env: request.env)
      end

      flash[:error] = _('There was a problem submitting your payment. You ' \
        'have not been charged. Please try again later.')

      json_redirect_to plan_path('pro')
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

  def check_has_current_subscription
    # TODO: This doesn't take the plan in to account
    return if @user.pro_account.try(:subscription?)
    flash[:notice] = _("You don't currently have a Pro subscription")
    redirect_to pro_plans_path
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

  def tax_percent
    (BigDecimal(AlaveteliConfiguration.stripe_tax_rate).to_f * 100).to_f
  end

  def check_plan_exists
    redirect_to(pro_plans_path) unless non_namespaced_plan_id
  end

  def prevent_duplicate_submission
    # TODO: This doesn't take the plan in to account
    return unless @user.pro_account.try(:subscription?)
    json_redirect_to alaveteli_pro_dashboard_path
  end

  def json_redirect_to(url)
    respond_to do |format|
      format.html { redirect_to url }
      format.json { render json: { url: url } }
    end
  end
end
