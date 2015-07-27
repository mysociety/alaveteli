# -*- encoding : utf-8 -*-
module RoutingFilter
  class Conditionallyprependlocale < RoutingFilter::Locale
    # Override core Locale filter not to prepend locale path segment
    # when there's only one locale
    def prepend_locale?(locale)
      locale && I18n.available_locales.length > 1 && (self.class.include_default_locale? || !default_locale?(locale))
    end
    # And override the generation logic to use FastGettext.locale
    # rather than I18n.locale (the latter is what rails uses
    # internally and may look like `en-US`, whereas the latter is
    # was FastGettext and other POSIX-based systems use, and will
    # look like `en_US`
    def around_generate(*args, &block)
      params = args.extract_options!                              # this is because we might get a call like forum_topics_path(forum, topic, :locale => :en)

      locale = params.delete(:locale)                             # extract the passed :locale option
      locale = FastGettext.locale if locale.nil?                         # default to I18n.locale when locale is nil (could also be false)
      locale = nil unless valid_locale?(locale)                   # reset to no locale when locale is not valid
      args << params

      yield.tap do |result|
        prepend_segment!(result, locale) if prepend_locale?(locale)
      end
    end

    # Reset the locale pattern when the locales are set.
    class << self
      def locales=(locales)
        @@locales_pattern = nil
        @@locales = locales.map(&:to_sym)
      end
    end
  end
end
