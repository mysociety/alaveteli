class AlaveteliPro::SubscriptionsController < AlaveteliPro::BaseController
  before_action :check_has_current_subscription, only: [:index]

  skip_before_action :html_response, only: [:create, :authorise]
  skip_before_action :pro_user_authenticated?, only: [:create, :authorise]
  before_action :authenticate, only: [:create, :authorise]

  before_action :check_allowed_to_subscribe_to_pro, only: [:create]
  before_action :prevent_duplicate_submission, only: [:create]
  before_action :load_plan, :load_coupon, only: [:create]

  def index
    @customer = current_user.pro_account.try(:stripe_customer)
    @subscriptions = current_user.pro_account.subscriptions
  end

  def create
    begin
      @pro_account = current_user.pro_account ||= current_user.build_pro_account

      # Ensure previous incomplete subscriptions are cancelled to prevent them
      # from using the new token/card
      @pro_account.subscriptions.incomplete.map(&:delete)

      @token = Stripe::Token.retrieve(params[:stripe_token])

      @pro_account.token = @token
      @pro_account.update_stripe_customer

      attributes = {
        plan: @plan.id,
        tax_percent: @plan.tax_percent,
        payment_behavior: 'allow_incomplete'
      }
      attributes[:coupon] = @coupon.id if @coupon

      @subscription = @pro_account.subscriptions.create(attributes)

    rescue ProAccount::CardError,
           Stripe::CardError => e
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
            ExceptionNotifier.notify_exception(e, env: request.env)
          end

          _('There was a problem submitting your payment. You ' \
            'have not been charged. Please try again later.')
        end
    end

    if flash[:error]
      json_redirect_to plan_path(@plan)
    else
      redirect_to authorise_subscription_path(@subscription.id)
    end
  end

  def authorise
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

      json_redirect_to plan_path(@subscription.plan)

    elsif @subscription.active?
      current_user.add_role(:pro)

      flash[:notice] = {
        partial: 'alaveteli_pro/subscriptions/signup_message'
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

  def destroy
    begin
      @customer = current_user.pro_account.try(:stripe_customer)
      raise ActiveRecord::RecordNotFound unless @customer

      @subscription = current_user.pro_account.subscriptions.
        retrieve(params[:id])
      @subscription.update(cancel_at_period_end: true)

      flash[:notice] = _('You have successfully cancelled your subscription ' \
                         'to {{pro_site_name}}',
                         pro_site_name: pro_site_name)

    rescue Stripe::RateLimitError,
           Stripe::InvalidRequestError,
           Stripe::AuthenticationError,
           Stripe::APIConnectionError,
           Stripe::StripeError => e
      if send_exception_notifications?
        ExceptionNotifier.notify_exception(e, env: request.env)
      end

      flash[:error] = _('There was a problem cancelling your account. Please ' \
                        'try again later.')
    end

    redirect_to subscriptions_path
  end

  private

  def authenticate
    authenticated? || ask_to_login(
      web: _('To upgrade your account'),
      email: _('Then you can upgrade your account'),
      email_subject: _('To upgrade your account')
    )
  end

  def check_allowed_to_subscribe_to_pro
    return if current_user.active?

    flash[:error] = _("Sorry, you can't sign up to {{pro_site_name}} at this " \
                      "time.", pro_site_name: pro_site_name)
    json_redirect_to pro_plans_path
  end

  def check_has_current_subscription
    # TODO: This doesn't take the plan in to account
    return if @user.pro_account.try(:subscription?)

    flash[:notice] = _("You don't currently have a Pro subscription")
    redirect_to pro_plans_path
  end

  def load_plan
    @plan = AlaveteliPro::Plan.retrieve(params[:plan_id])
    @plan || redirect_to(pro_plans_path)
  end

  def load_coupon
    @coupon = AlaveteliPro::Coupon.retrieve(params[:coupon_code])
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
