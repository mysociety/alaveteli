# -*- encoding : utf-8 -*-
# app/helpers/link_to_helper.rb:
# This module is included into all controllers via controllers/application.rb
# -
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

module LinkToHelper

  # Links to various models

  # Requests
  def request_url(info_request, options = {})
    show_request_url({:url_title => info_request.url_title}.merge(options))
  end

  def request_path(info_request, options = {})
    request_url(info_request, options.merge(:only_path => true))
  end

  def request_link(info_request, cls=nil)
    link_to info_request.title, request_path(info_request), :class => cls
  end

  def request_details_path(info_request)
    details_request_path(:url_title => info_request.url_title)
  end

  # Incoming / outgoing messages
  def incoming_message_url(incoming_message, options = {})
    message_url(incoming_message, options)
  end

  def incoming_message_path(incoming_message, options = {})
    message_path(incoming_message, options)
  end

  def outgoing_message_url(outgoing_message, options = {})
    message_url(outgoing_message, options)
  end

  def outgoing_message_path(outgoing_message, options = {})
    message_path(outgoing_message, options)
  end

  def comment_url(comment, options = {})
    request_url(comment.info_request, options.merge(:anchor => "comment-#{comment.id}"))
  end

  def comment_path(comment, options = {})
    comment_url(comment, options.merge(:only_path => true))
  end

  # Used in mailers where we want to give a link to a new response
  def new_response_url(info_request, incoming_message)
    if info_request.user.is_pro?
      # Pro users will always need to log in, so we have to give them a link
      # which forces that
      message_url = incoming_message_url(incoming_message, :cachebust => true)
      signin_url(:r => message_url)
    else
      # For normal users, we try not to use a login link here, just the
      # actual URL. This is because people tend to forward these emails
      # amongst themselves.
      incoming_message_url(incoming_message, :cachebust => true)
    end
  end

  # Respond to request
  def respond_to_last_url(info_request, options = {})
    last_response = info_request.get_last_public_response
    if last_response.nil?
      new_request_followup_url(options.merge(:request_id => info_request.id))
    else
      new_request_incoming_followup_url(options.merge(:request_id => info_request.id, :incoming_message_id => last_response.id))
    end
  end

  def respond_to_last_path(info_request, options = {})
    respond_to_last_url(info_request, options.merge(:only_path => true))
  end

  # Public bodies
  def public_body_url(public_body, options = {})
    public_body.url_name.nil? ? '' : show_public_body_url(options.merge(:url_name => public_body.url_name))
  end

  def public_body_path(public_body, options = {})
    public_body_url(public_body, options.merge(:only_path => true))
  end

  def public_body_link_short(public_body)
    link_to public_body.short_or_long_name, public_body_path(public_body)
  end

  def public_body_link(public_body, cls=nil)
    link_to public_body.name, public_body_path(public_body), :class => cls
  end

  def public_body_link_absolute(public_body) # e.g. for in RSS
    link_to public_body.name, public_body_url(public_body)
  end

  # Users
  def user_url(user, options = {})
    show_user_url(options.merge(:url_name => user.url_name))
  end

  def user_path(user, options = {})
    user_url(user, options.merge(:only_path => true))
  end

  def user_link(user, cls=nil)
    link_to user.name, user_path(user), :class => cls
  end

  def user_link_for_request(request, cls=nil)
    if request.is_external?
      user_name = request.external_user_name || _("Anonymous user")
      if !request.external_url.nil?
        link_to user_name, request.external_url
      else
        user_name
      end
    else
      link_to request.user.name, user_path(request.user), :class => cls
    end
  end

  def user_admin_link_for_request(request, external_text=nil, internal_text=nil)
    if request.is_external?
      external_text || (request.external_user_name || _("Anonymous user")) + " (external)"
    else
      link_to(internal_text || request.user.name, admin_user_url(request.user))
    end
  end

  def user_link_absolute(user)
    link_to user.name, user_url(user)
  end

  def user_link(user)
    link_to user.name, user_path(user)
  end

  def external_user_link(request, absolute, text)
    if request.external_user_name
      request.external_user_name
    else
      if absolute
        url = help_privacy_url(:anchor => 'anonymous')
      else
        url = help_privacy_path(:anchor => 'anonymous')
      end
      link_to(text, url)
    end
  end

  def request_user_link_absolute(request, anonymous_text=_("Anonymous user"))
    if request.is_external?
      external_user_link(request, absolute=true, anonymous_text)
    else
      user_link_absolute(request.user)
    end
  end

  def request_user_link(request, anonymous_text=_("Anonymous user"))
    if request.is_external?
      external_user_link(request, absolute=false, anonymous_text)
    else
      user_link(request.user)
    end
  end

  def user_or_you_link(user)
    if @user && user == @user
      link_to h("you"), user_path(user)
    else
      link_to h(user.name), user_path(user)
    end
  end

  def user_or_you_capital(user)
    if @user && user == @user
      return h("You")
    else
      return h(user.name)
    end
  end

  def user_or_you_capital_link(user)
    link_to user_or_you_capital(user), user_path(user)
  end

  def user_admin_link(user, name="admin", cls=nil)
    link_to name, admin_user_url(user), :class => cls
  end

  # Tracks. feed can be 'track' or 'feed'
  def do_track_url(track_thing, feed = 'track', options = {})
    if track_thing.track_type == 'request_updates'
      track_request_url(options.merge(:url_title => track_thing.info_request.url_title, :feed => feed))
    elsif track_thing.track_type == 'all_new_requests'
      track_list_url(options.merge(:view => 'recent', :feed => feed))
    elsif track_thing.track_type == 'all_successful_requests'
      track_list_url(options.merge(:view => 'successful', :feed => feed))
    elsif track_thing.track_type == 'public_body_updates'
      track_public_body_url(options.merge(:url_name => track_thing.public_body.url_name, :feed => feed))
    elsif track_thing.track_type == 'user_updates'
      track_user_url(options.merge(:url_name => track_thing.tracked_user.url_name, :feed => feed))
    elsif track_thing.track_type == 'search_query'
      track_search_url(options.merge(:query_array => track_thing.track_query, :feed => feed))
    else
      raise "unknown tracking type " + track_thing.track_type
    end
  end

  def do_track_path(track_thing, feed = 'track', options = {})
    do_track_url(track_thing, feed, options.merge(:only_path => true))
  end

  # General pages.
  def search_url(query, options = nil)
    if query.kind_of?(Array)
      query = query - ["", nil]
      query = query.join("/")
    end
    routing_info = {:controller => 'general',
                    :action => 'search',
                    :combined => query,
                    :view => nil}
    if !options.nil?
      routing_info = options.merge(routing_info)
    end
    url = url_for(routing_info)
    # Here we can't escape the slashes, as RFC 2396 doesn't allow slashes
    # within a path component. Rails is assuming when generating URLs that
    # either there aren't slashes, or we are in a query part where you can
    # have escaped slashes. Apache complains if you do include slashes
    # within a path component.
    # See http://www.webmasterworld.com/apache/3279075.htm
    # and also 3.3 of http://www.ietf.org/rfc/rfc2396.txt
    # It turns out this is a regression in Rails 2.1, caused by this bug fix:
    #   http://rails.lighthouseapp.com/projects/8994/tickets/144-patch-bug-in-rails-route-globbing
    url = url.gsub("%2F", "/")

    return url
  end

  def search_path(query, options = {})
    search_url(query, options.merge(:only_path => true))
  end

  def search_link(query)
    link_to h(query), search_url(query)
  end

  # About page URLs
  def about_url(options = {})
    help_general_url(options.merge(template: 'about'))
  end

  def unhappy_url(info_request = nil, options = {})
    if info_request.nil?
      return help_general_url(options.merge(template: 'unhappy'))
    else
      return help_unhappy_url(options.merge(url_title: info_request.url_title))
    end
  end

  def current_path_with_locale(locale)
    unsafe_keys = %w[protocol host]
    sanitized_params = params.reject { |k| unsafe_keys.include?(k) }.permit!
    url_for(sanitized_params.merge(locale: locale, only_path: true))
  end

  private

  # Private: Generate a request_url linking to the new correspondence
  def message_url(message, options = {})
    message_type = message.class.to_s.gsub('Message', '').downcase

    default_options = { :anchor => "#{ message_type }-#{ message.id }" }

    if options.delete(:cachebust)
      default_options.merge!(:nocache => "#{ message_type }-#{ message.id }")
    end

    request_url(message.info_request, options.merge(default_options))
  end

  def message_path(message, options = {})
    message_url(message, options.merge(:only_path => true))
  end

end
