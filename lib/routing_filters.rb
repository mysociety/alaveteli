module RoutingFilter
  class Conditionallyprependlocale < RoutingFilter::Locale
    # Override core Locale filter not to prepend locale path segment
    # when there's only one locale
    def prepend_locale?(locale)
      locale &&
        AlaveteliLocalization.available_locales.length > 1 &&
        (self.class.include_default_locale? || !default_locale?(locale))
    end
    # And override the generation logic to use FastGettext.locale
    # rather than I18n.locale (the latter is what rails uses
    # internally and may look like `en-US`, whereas the former is
    # what FastGettext and other POSIX-based systems use, and will
    # look like `en_US`
    def around_generate(*args, &block)
      # this is because we might get a call like forum_topics_path(forum, topic, :locale => :en)
      params = args.extract_options!
      # extract the passed :locale option
      locale = params.delete(:locale)
      if locale.nil?
        # default to underscore locale when locale is nil (could also be false)
        locale = AlaveteliLocalization.locale
      end
      unless valid_locale?(locale)
        # reset to no locale when locale is not valid
        locale = nil
      end
      args << params

      yield.tap do |result|
        next unless prepend_locale?(locale)

        result.update prepend_segment(result.url, locale)
      end
    end

    def default_locale?(locale)
      AlaveteliLocalization.default_locale?(locale)
    end

    # Reset the locale pattern when the locales are set.
    class << self
      def locales_pattern
        %r(^/(#{locales.map { |l| Regexp.escape(l.to_s) }.join('|')})(?=/|$))
      end
    end
  end
end

ActionDispatch::Routing::RouteSet::NamedRouteCollection::UrlHelper.class_eval do
  def self.optimize_helper?(route)
    false
  end
end
