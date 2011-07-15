module RoutingFilter
  class Conditionallyprependlocale < RoutingFilter::Locale
      # Override core Locale filter not to prepend locale path segment
      # when there's only one locale
      def prepend_locale?(locale)
        locale && I18n.available_locales.length > 1 && (self.class.include_default_locale? || !default_locale?(locale))
      end
  end
end
