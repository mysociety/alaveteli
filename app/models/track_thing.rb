# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: track_things
#
#  id               :integer          not null, primary key
#  tracking_user_id :integer          not null
#  track_query      :string(255)      not null
#  info_request_id  :integer
#  tracked_user_id  :integer
#  public_body_id   :integer
#  track_medium     :string(255)      not null
#  track_type       :string(255)      default("internal_error"), not null
#  created_at       :datetime
#  updated_at       :datetime
#

# models/track_thing.rb:
# When somebody is getting alerts for something.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

require 'set'

# TODO: TrackThing looks like a good candidate for single table inheritance

class TrackThing < ActiveRecord::Base
  # { TRACK_TYPE => DESCRIPTION }
  TRACK_TYPES = { 'request_updates'         => _('Individual requests'),
                  'all_new_requests'        => _('Many requests'),
                  'all_successful_requests' => _('Many requests'),
                  'public_body_updates'     => _('Public authorities'),
                  'user_updates'            => _('People'),
                  'search_query'            => _('Search queries') }

  TRACK_MEDIUMS = %w(email_daily feed)

  belongs_to :info_request
  belongs_to :public_body
  belongs_to :tracking_user, :class_name => 'User'
  belongs_to :tracked_user, :class_name => 'User'
  has_many :track_things_sent_emails

  validates_presence_of :track_query
  validates_presence_of :track_type
  validates_inclusion_of :track_type, :in => TRACK_TYPES.keys
  validates_inclusion_of :track_medium, :in => TRACK_MEDIUMS

  # When constructing a new track, use this to avoid duplicates / double
  # posting
  def self.find_existing(tracking_user, track)
    return nil if tracking_user.nil?
    where(:tracking_user_id => tracking_user.id,
          :track_query => track.track_query,
          :track_type => track.track_type).first
  end

  def self.track_type_description(track_type)
    TRACK_TYPES.fetch(track_type) { raise "internal error #{ track_type }" }
  end

  def self.create_track_for_request(info_request)
    track_thing = TrackThing.new
    track_thing.track_type = 'request_updates'
    track_thing.info_request = info_request
    track_thing.track_query = "request:#{ info_request.url_title }"
    track_thing
  end

  def self.create_track_for_all_new_requests
    track_thing = TrackThing.new
    track_thing.track_type = 'all_new_requests'
    track_thing.track_query = "variety:sent"
    track_thing
  end

  def self.create_track_for_all_successful_requests
    track_thing = TrackThing.new
    track_thing.track_type = 'all_successful_requests'
    track_thing.track_query = 'variety:response (status:successful OR status:partially_successful)'
    track_thing
  end

  def self.create_track_for_public_body(public_body, event_type = nil)
    track_thing = TrackThing.new
    track_thing.track_type = 'public_body_updates'
    track_thing.public_body = public_body
    query = "requested_from:#{ public_body.url_name }"
    if InfoRequestEvent.enumerate_event_types.include?(event_type)
      query += " variety:#{ event_type }"
    end
    track_thing.track_query = query
    track_thing
  end

  def self.create_track_for_user(user)
    track_thing = TrackThing.new
    track_thing.track_type = 'user_updates'
    track_thing.tracked_user = user
    track_thing.track_query = "requested_by:#{ user.url_name } OR commented_by: #{ user.url_name }"
    track_thing
  end

  def self.create_track_for_search_query(query, variety_postfix = nil)
    track_thing = TrackThing.new
    track_thing.track_type = 'search_query'
    unless query =~ /variety:/
      case variety_postfix
      when "requests"
        query += " variety:sent"
      when "users"
        query += " variety:user"
      when "bodies"
        query += " variety:authority"
      end
    end
    track_thing.track_query = query
    # TODO: should extract requested_by:, request:, requested_from:
    # and stick their values into the respective relations.
    # Should also update "params" to make the list_description
    # nicer and more generic.  It will need to do some clever
    # parsing of the query to do this nicely
    track_thing
  end

  def track_type_description
    TrackThing.track_type_description(track_type)
  end

  def track_query_description
    filter_description = query_filter_description('(variety:sent OR variety:followup_sent OR variety:response OR variety:comment)',
                                                  :no_query => N_("all requests or comments"),
                                                  :query => N_("all requests or comments matching text '{{query}}'"))
    return filter_description if filter_description

    filter_description = query_filter_description('(latest_status:successful OR latest_status:partially_successful)',
                                                  :no_query => N_("requests which are successful"),
                                                  :query => N_("requests which are successful matching text '{{query}}'"))
    return filter_description if filter_description

    _("anything matching text '{{query}}'", :query => track_query)
  end

  # Return a readable query description for queries involving commonly used
  # filter clauses
  def query_filter_description(string, options)
    parsed_query = track_query.gsub(string, '')
    if parsed_query != track_query
      parsed_query.strip!
      if parsed_query.empty?
        _(options[:no_query])
      else
        _(options[:query], :query => parsed_query)
      end
    end
  end

  # Return hash of text parameters based on the track_type describing the
  # request etc.
  def params
    @params ||= params_for(track_type)
  end

  private

  def params_for(track_type)
    if respond_to?("#{ track_type }_params", true)
      send("#{ track_type }_params")
    else
      raise "unknown tracking type #{ track_type }"
    end
  end

  def request_updates_params
    { # Website
      :verb_on_page => _("Follow this request"),
      :verb_on_page_already => _("You are already following this request"),
      # Email
      :title_in_email => _("New updates for the request '{{request_title}}'",
                           :request_title => info_request.title.html_safe),
      :title_in_rss => _("New updates for the request '{{request_title}}'",
                         :request_title => info_request.title),
      # Authentication
      :web => _("To follow the request '{{request_title}}'",
                :request_title => info_request.title),
      :email => _("Then you will be updated whenever the request '{{request_title}}' is updated.",
                  :request_title => info_request.title),
      :email_subject => _("Confirm you want to follow the request '{{request_title}}'",
                          :request_title => info_request.title),
      # RSS sorting
      :feed_sortby => 'newest'
      }
  end

  def all_new_requests_params
    { # Website
      :verb_on_page => _("Follow all new requests"),
      :verb_on_page_already => _("You are already following new requests"),
      # Email
      :title_in_email => _("New Freedom of Information requests"),
      :title_in_rss => _("New Freedom of Information requests"),
      # Authentication
      :web => _("To follow new requests"),
      :email => _("Then you will be following all new FOI requests."),
      :email_subject => _("Confirm you want to follow new requests"),
      # RSS sorting
      :feed_sortby => 'newest'
      }
  end

  def all_successful_requests_params
    { # Website
      :verb_on_page => _("Follow new successful responses"),
      :verb_on_page_already => _("You are following all new successful responses"),
      # Email
      :title_in_email => _("Successful Freedom of Information requests"),
      :title_in_rss => _("Successful Freedom of Information requests"),
      # Authentication
      :web => _("To follow all successful requests"),
      :email => _("Then you will be notified whenever an FOI request succeeds."),
      :email_subject => _("Confirm you want to follow all successful FOI requests"),
      # RSS sorting - used described date, as newest would give a
      # date for responses possibly days before description, so
      # wouldn't appear at top of list when description (known
      # success) causes match.
      :feed_sortby => 'described'
      }
  end

  def public_body_updates_params
    { # Website
      :verb_on_page => _("Follow requests to {{public_body_name}}",
                         :public_body_name => public_body.name),
      :verb_on_page_already => _("Following"),
      # Email
      :title_in_email => _("{{foi_law}} requests to '{{public_body_name}}'",
                           :foi_law => public_body.law_only_short,
                           :public_body_name => public_body.name),
      :title_in_rss => _("{{foi_law}} requests to '{{public_body_name}}'",
                         :foi_law => public_body.law_only_short,
                         :public_body_name => public_body.name),
      # Authentication
      :web => _("To follow requests made using {{site_name}} to the public authority '{{public_body_name}}'",
                :site_name => AlaveteliConfiguration.site_name,
                :public_body_name => public_body.name),
      :email => _("Then you will be notified whenever someone requests something or gets a response from '{{public_body_name}}'.",
                  :public_body_name => public_body.name),
      :email_subject => _("Confirm you want to follow requests to '{{public_body_name}}'",
                          :public_body_name => public_body.name),
      # RSS sorting
      :feed_sortby => 'newest'
      }
  end

  def user_updates_params
    { # Website
      :verb_on_page => _("Follow this person"),
      :verb_on_page_already => _("You are already following this person"),
      # Email
      :title_in_email => _("FOI requests by '{{user_name}}'",
                           :user_name => tracked_user.name.html_safe),
      :title_in_rss => _("FOI requests by '{{user_name}}'",
                         :user_name => tracked_user.name),
      # Authentication
      :web => _("To follow requests by '{{user_name}}'",
                :user_name => tracked_user.name),
      :email => _("Then you will be notified whenever '{{user_name}}' requests something or gets a response.",
                  :user_name => tracked_user.name),
      :email_subject => _("Confirm you want to follow requests by '{{user_name}}'",
                          :user_name => tracked_user.name),
      # RSS sorting
      :feed_sortby => 'newest'
      }
  end

  def search_query_params
    { # Website
      :verb_on_page => _("Follow things matching this search"),
      :verb_on_page_already => _("You are already following things matching this search"),
      # Email
      :title_in_email => _("Requests or responses matching your saved search"),
      :title_in_rss => _("Requests or responses matching your saved search"),
      # Authentication
      :web => _("To follow requests and responses matching your search"),
      :email => _("Then you will be notified whenever a new request or response matches your search."),
      :email_subject => _("Confirm you want to follow new requests or responses matching your search"),
      # RSS sorting - TODO: hmmm, we don't really know which to use
      # here for sorting. Might be a query term (e.g. 'cctv'), in
      # which case newest is good, or might be something like
      # all refused requests in which case want to sort by
      # described (when we discover criteria is met). Rather
      # conservatively am picking described, as that will make
      # things appear in feed more than the should, rather than less.
      :feed_sortby => 'described'
      }
  end

end
