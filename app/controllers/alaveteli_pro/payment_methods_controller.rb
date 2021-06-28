class AlaveteliPro::PaymentMethodsController < AlaveteliPro::BaseController
  before_action :authenticate

  def update
    begin
      @token = Stripe::Token.retrieve(params[:stripe_token])

      @pro_account = current_user.pro_account ||= current_user.build_pro_account
      @pro_account.source = @token.id
      @pro_account.update_stripe_customer

      flash[:notice] = _('Your payment details have been updated')

    rescue Stripe::CardError => e
      flash[:error] = e.message

    rescue Stripe::RateLimitError,
           Stripe::InvalidRequestError,
           Stripe::AuthenticationError,
           Stripe::APIConnectionError,
           Stripe::StripeError => e

      if send_exception_notifications?
        ExceptionNotifier.notify_exception(e, :env => request.env)
      end

      flash[:error] = _('There was a problem updating your payment details. ' \
                        'Please try again later.')
    end

    redirect_to subscriptions_path
  end

  private

  def authenticate
    post_redirect_params = {
      :web => _('To update your payment details'),
      :email => _('Then you can update your payment details'),
      :email_subject => _('To update your payment details') }
    authenticated?(post_redirect_params)
  end

end
