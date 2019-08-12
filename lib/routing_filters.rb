# -*- encoding : utf-8 -*-
module RoutingFilter
  class Conditionallyprependlocale < RoutingFilter::Locale
    # We need to be able to override this class attribute so from Rails 4.0
    # onwards we're going to need write access. It looks as though we don't
    # use the equivalent instance variables so we can opt out of creating
    # accessors for them
    cattr_accessor :locales, instance_accessor: false

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
      params = args.extract_options!                              # this is because we might get a call like forum_topics_path(forum, topic, :locale => :en)

      locale = params.delete(:locale)                             # extract the passed :locale option
      locale = AlaveteliLocalization.locale if locale.nil?        # default to underscore locale when locale is nil (could also be false)
      locale = nil unless valid_locale?(locale)                   # reset to no locale when locale is not valid
      args << params

      yield.tap do |result|
        prepend_segment!(result, locale) if prepend_locale?(locale)
      end
    end

    def default_locale?(locale)
      AlaveteliLocalization.default_locale?(locale)
    end

    # Reset the locale pattern when the locales are set.
    class << self
      def locales_pattern
        super
      end

      def locales=(locales)
        @@locales_pattern = nil
        @@locales = locales.map(&:to_sym)
      end
    end
  end
end

ActionDispatch::Routing::RouteSet::NamedRouteCollection::UrlHelper.class_eval do
  def self.optimize_helper?(route)
    false
  end
end
