##
# Helpers for the locale switcher.
#
module LocalesHelper
  def current_locale
    AlaveteliLocalization.locale
  end

  def switchable_locales
    AlaveteliLocalization.available_locales - [current_locale]
  end
end
