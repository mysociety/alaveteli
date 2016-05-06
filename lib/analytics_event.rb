# -*- encoding : utf-8 -*-
module AnalyticsEvent

  # modules for standardising Strings used for event categories and actions

  module Category
    WIDGET_CLICK = "Widget Clicked"
    OUTBOUND = "Outbound Link"
  end

  module Action
    FACEBOOK_EXIT = 'Facebook Exit'
    TWITTER_EXIT = 'Twitter Exit'
    WORDPRESS_EXIT = 'WordPress Exit'
    WIDGET_VOTE = 'Vote'
    WIDGET_SIGNIN = 'Sign in to track'
    WIDGET_UNSUB = 'Unsubscribe'
  end

end
