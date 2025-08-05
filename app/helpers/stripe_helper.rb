module StripeHelper
  STRIPE_SUPPORTED_LOCALES = %w[
    da de en es fi fr it ja nb nl pl pt sv zh
  ].freeze

  def stripe_locale
    if STRIPE_SUPPORTED_LOCALES.include?(@locales[:current])
      @locales[:current]
    else
      'auto'
    end
  end
end
