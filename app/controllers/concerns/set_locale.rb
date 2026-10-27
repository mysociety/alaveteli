##
# Set the locale for the request from the stored locale, the browser's
# preference or the default locale, and store it for subsequent requests.
#
module SetLocale
  extend ActiveSupport::Concern

  included do
    before_action :set_gettext_locale, :store_gettext_locale
  end

  private

  # This is an override of the method provided by gettext_i18n_rails.
  # AlaveteliLocalization.set_session_locale explicitly sets I18n.locale,
  # required due to the I18nProxy used in Rails to trigger the
  # lookup_context and expire the template cache
  def set_gettext_locale
    AlaveteliLocalization.set_session_locale(
      stored_locale, *browser_locales, AlaveteliLocalization.default_locale
    )

    # set response header informing the browser what language the page is in
    response.headers['Content-Language'] = I18n.locale.to_s
  end

  def store_gettext_locale
    # set the current stored locale to the requested_locale
    locale = AlaveteliLocalization.locale
    cookies[:locale] = locale

    # ensure current user locale attribute is up-to-date
    current_user.update_column(:locale, locale) if current_user
  end

  # The locale stored in the cookie, unless it's no longer available, so that
  # we fall back to the browser's preference rather than the default.
  # #store_gettext_locale then replaces an unavailable locale.
  def stored_locale
    locale = cookies[:locale]
    locale if AlaveteliLocalization.available_locales.include?(locale)
  end

  # The locales from the browser's Accept-Language header, in the order given
  def browser_locales
    return [] unless AlaveteliConfiguration.use_default_browser_language

    request.env['HTTP_ACCEPT_LANGUAGE'].to_s.split(',').map do
      _1.split(';', 2)[0]
    end
  end
end
