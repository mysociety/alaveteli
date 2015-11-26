# -*- encoding : utf-8 -*-
module TrackHelper

  def already_subscribed_notice(track_thing)
    case track_thing.track_type
    when 'request_updates'
      _("You are already subscribed to '{{request_url}}', a request.",
        :request_url => request_link(track_thing.info_request))
    when 'all_new_requests'
      _('You are already subscribed to any <a href="{{new_requests_url}}">new requests</a>.',
        :new_requests_url => request_list_path)
    when 'all_successful_requests'
      _('You are already subscribed to any <a href="{{successful_requests_url}}">successful requests</a>.',
        :successful_requests_url => request_list_successful_path )
    when 'public_body_updates'
      _("You are already subscribed to '{{authority_url}}', a public authority.",
        :authority_url => public_body_link(track_thing.public_body))
    when 'user_updates'
      _("You are already subscribed to '{{user_url}}', a person.",
        :user_url => user_link(track_thing.tracked_user))
    when 'search_query'
      _('You are already subscribed to <a href="{{search_url}}">this search</a>.',
        :search_url => search_path([track_thing.track_query, 'newest', 'advanced']))
    end
  end

  def subscribe_email_notice(track_thing)
    case track_thing.track_type
    when 'request_updates'
      _("You will now be emailed updates about '{{request_url}}', a request.",
        :request_url => request_link(track_thing.info_request))
    when 'all_new_requests'
      _('You will now be emailed updates about any <a href="{{new_requests_url}}">new requests</a>.',
        :new_requests_url => request_list_path)
    when 'all_successful_requests'
      _('You will now be emailed updates about <a href="{{successful_requests_url}}">successful requests</a>.',
        :successful_requests_url => request_list_successful_path )
    when 'public_body_updates'
      _("You will now be emailed updates about '{{authority_url}}', a public authority.",
        :authority_url => public_body_link(track_thing.public_body))
    when 'user_updates'
      _("You will now be emailed updates about '{{user_url}}', a person.",
        :user_url => user_link(track_thing.tracked_user))
    when 'search_query'
      _("You will now be emailed updates about <a href=\"{{search_url}}\">this search</a>.",
        :search_url => search_path([track_thing.track_query, 'newest', 'advanced']))
    end
  end

  def subscribe_follow_notice(track_thing)
    wall_url_user = show_user_wall_path(:url_name => track_thing.tracking_user.url_name)
    case track_thing.track_type
    when 'request_updates'
      _('You are now <a href="{{wall_url_user}}">following</a> updates ' \
           'about \'{{request_url}}\', a request.',
        :request_url => request_link(track_thing.info_request),
        :wall_url_user => wall_url_user)
    when 'all_new_requests'
      _('You are now <a href="{{wall_url_user}}">following</a> updates ' \
           'about <a href="{{new_requests_url}}">new requests</a>.',
        :new_requests_url => request_list_path,
        :wall_url_user => wall_url_user)
    when 'all_successful_requests'
      _('You are now <a href="{{wall_url_user}}">following</a> updates about ' \
           '<a href="{{successful_requests_url}}">successful requests</a>.',
        :successful_requests_url => request_list_successful_path,
        :wall_url_user => wall_url_user)
    when 'public_body_updates'
      _('You are now <a href="{{wall_url_user}}">following</a> updates ' \
           'about \'{{authority_url}}\', a public authority.',
        :wall_url_user => wall_url_user,
        :authority_url => public_body_link(track_thing.public_body))
    when 'user_updates'
      _('You are now <a href="{{wall_url_user}}">following</a> updates ' \
           'about \'{{user_url}}\', a person.',
        :wall_url_user => wall_url_user,
        :user_url => user_link(track_thing.tracked_user))
    when 'search_query'
      _('You are now <a href="{{wall_url_user}}">following</a> updates ' \
           'about <a href="{{search_url}}">this search</a>.',
        :wall_url_user => wall_url_user,
        :search_url => search_path([track_thing.track_query, 'newest', 'advanced']))
    end
  end

  def unsubscribe_notice(track_thing)
    case track_thing.track_type
    when 'request_updates'
      _("You are no longer following '{{request_url}}', a request.",
        :request_url => request_link(track_thing.info_request))
    when 'all_new_requests'
      _('You are no longer following <a href="{{new_requests_url}}">new ' \
           'requests</a>.',
        :new_requests_url => request_list_path)
    when 'all_successful_requests'
      _('You are no longer following <a href="{{successful_requests_url}}">' \
           'successful requests</a>.',
        :successful_requests_url => request_list_successful_path )
    when 'public_body_updates'
      _("You are no longer following '{{authority_url}}', a public authority.",
        :authority_url => public_body_link(track_thing.public_body))
    when 'user_updates'
      _("You are no longer following '{{user_url}}', a person.",
        :user_url => user_link(track_thing.tracked_user))
    when 'search_query'
      _('You are no longer following <a href="{{search_url}}">this search</a>.',
        :search_url => search_path([track_thing.track_query, 'newest', 'advanced']))
    end
  end

  def track_description(track_thing)
    case track_thing.track_type
    when 'request_updates'
      _("'{{request_url}}', a request",
        :request_url => request_link(track_thing.info_request))
    when 'all_new_requests'
      link_to(_('new requests'), request_list_path)
    when 'all_successful_requests'
      link_to(_('successful requests'), request_list_successful_path)
    when 'public_body_updates'
      _("'{{authority_url}}', a public authority",
        :authority_url => public_body_link(track_thing.public_body))
    when 'user_updates'
      _("'{{user_url}}', a person",
        :user_url => user_link(track_thing.tracked_user))
    when 'search_query'
      link_to(track_thing.track_query_description,
              search_path([track_thing.track_query, 'newest', 'advanced']))
    end
  end
end
