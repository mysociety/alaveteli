# -*- encoding : utf-8 -*-
module AnalyticsEvent

  # modules for standardising Strings used for event categories and actions

  module Category
    WIDGET_CLICK = "Widget Clicked"
    OUTBOUND = "Outbound Link"
    PRO_NAV_CLICK = "Pro Navigation Clicked"
    VIEW_REQUEST = "View Request"
    SEARCH_OFFICIAL_WEBSITE = "Search Official Website"
  end

  module Action
    FACEBOOK_EXIT = 'Facebook Exit'
    MEDIUM_EXIT = 'Medium Exit'
    TWITTER_EXIT = 'Twitter Exit'
    WORDPRESS_EXIT = 'WordPress Exit'
    WIDGET_VOTE = 'Vote'
    WIDGET_SIGNIN = 'Sign in to track'
    WIDGET_UNSUB = 'Unsubscribe'
    PRO_NAV_DASHBOARD = "Dashboard"
    PRO_NAV_REQUESTS = "Requests"
    PRO_NAV_MAKE_REQUEST = "Make request"
    PRO_NAV_BROWSE_PUBLIC = "Browse public requests"
    PRO_NAV_VIEW_AUTHORITIES = "View authorities"
    PRO_NAV_READ_BLOG = "Read blog"
    PRO_NAV_HELP = "Help"
    PRO_NAV_PROFILE = "Profile"
    PRO_NAV_WALL = "Wall"
    POSSIBLE_RELATED = "Possible related requests"
  end

end
