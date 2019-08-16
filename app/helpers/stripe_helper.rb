module StripeHelper
  STRIPE_SUPPORTED_LOCALES = %w[
    da de en es fi fr it ja nb nl pl pt sv zh
  ].freeze

  def stripe_button(options = {})
    content_tag :script, '', stripe_button_default_options.deep_merge(
      data: options
    )
  end

  def stripe_locale
    if STRIPE_SUPPORTED_LOCALES.include?(@locales[:current])
      @locales[:current]
    else
      'auto'
    end
  end

  private

  def stripe_button_default_options
    {
      src: 'https://checkout.stripe.com/checkout.js',
      class: 'stripe-button',
      data: {
        key: AlaveteliConfiguration.stripe_publishable_key,
        name: AlaveteliConfiguration.pro_site_name,
        allow_remember_me: false,
        email: current_user.email,
        image: 'https://s3.amazonaws.com/stripe-uploads/acct_19EbqNIbP0iBLddtmerchant-icon-1479145884111-mysociety-wheel-logo.png',
        locale: 'auto',
        zip_code: true
      }
    }
  end
end
