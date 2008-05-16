# == Schema Information
# Schema version: 54
#
# Table name: track_things
#
#  id               :integer         not null, primary key
#  tracking_user_id :integer         not null
#  track_query      :string(255)     not null
#  info_request_id  :integer         
#  tracked_user_id  :integer         
#  public_body_id   :integer         
#  track_medium     :string(255)     not null
#  track_type       :string(255)     not null
#  created_at       :datetime        
#  updated_at       :datetime        
#

# models/track_thing.rb:
# When somebody is getting alerts for something.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: track_thing.rb,v 1.21 2008-05-16 00:05:09 francis Exp $

class TrackThing < ActiveRecord::Base
    belongs_to :tracking_user, :class_name => 'User'
    validates_presence_of :track_query
    validates_presence_of :track_type

    belongs_to :info_request
    belongs_to :public_body
    belongs_to :tracked_user, :class_name => 'User'

    has_many :track_things_sent_emails

    validates_inclusion_of :track_type, :in => [ 
        'request_updates', 
        'all_new_requests',
        'all_successful_requests',
        'public_body_updates', 
        'user_updates',
        'search_query'
    ]

    validates_inclusion_of :track_medium, :in => [ 
        'email_daily', 
        'feed'
    ]

    def TrackThing.create_track_for_request(info_request)
        track_thing = TrackThing.new
        track_thing.track_type = 'request_updates'
        track_thing.info_request = info_request
        track_thing.track_query = "request:" + info_request.url_title
        return track_thing
    end

    def TrackThing.create_track_for_all_new_requests
        track_thing = TrackThing.new
        track_thing.track_type = 'all_new_requests'
        track_thing.track_query = "variety:sent"
        return track_thing
    end

    def TrackThing.create_track_for_all_successful_requests
        track_thing = TrackThing.new
        track_thing.track_type = 'all_successful_requests'
        track_thing.track_query = 'variety:response (status:successful OR status:partially_successful)'
        return track_thing
    end

    def TrackThing.create_track_for_public_body(public_body)
        track_thing = TrackThing.new
        track_thing.track_type = 'public_body_updates'
        track_thing.public_body = public_body
        track_thing.track_query = "variety:sent requested_from:" + public_body.url_name
        return track_thing
    end

    def TrackThing.create_track_for_user(user)
        track_thing = TrackThing.new
        track_thing.track_type = 'user_updates'
        track_thing.tracked_user = user
        track_thing.track_query = "variety:sent requested_by:" + user.url_name
        return track_thing
    end

    def TrackThing.create_track_for_search_query(query)
        track_thing = TrackThing.new
        track_thing.track_type = 'search_query'
        track_thing.track_query = query
        return track_thing
    end

    # Return hash of text parameters describing the request etc.
    include LinkToHelper
    def params
        if @params.nil?
            if self.track_type == 'request_updates'
                @params = {
                    # Website
                    :set_title => "How would you like to track the request '" + CGI.escapeHTML(self.info_request.title) + "'?",
                    :list_description => "'<a href=\"/request/" + CGI.escapeHTML(self.info_request.url_title) + "\">" + CGI.escapeHTML(self.info_request.title) + "</a>', a request", # XXX yeuch, sometimes I just want to call view helpers from the model, sorry! can't work out how 
                    :verb_on_page => "Track updates to this request",
                    :verb_on_page_already => "tracking this request",
                    # Email
                    :title_in_email => "New updates for the request '" + self.info_request.title + "'",
                    :title_in_rss => "New updates for the request '" + self.info_request.title + "'",
                    # Authentication
                    :web => "To follow updates to the request '" + CGI.escapeHTML(self.info_request.title) + "'",
                    :email => "Then you will be emailed whenever the request '" + CGI.escapeHTML(self.info_request.title) + "' is updated.",
                    :email_subject => "Confirm you want to follow updates to the request '" + CGI.escapeHTML(self.info_request.title) + "'",
                }
            elsif self.track_type == 'all_new_requests'
                @params = {
                    # Website
                    :set_title => "How would you like to be told about any new requests?",
                    :list_description => "any <a href=\"/list\">new requests</a>",
                    :verb_on_page => "Be told about any new requests",
                    :verb_on_page_already => "being told about any new requests",
                    # Email
                    :title_in_email => "New Freedom of Information requests",
                    :title_in_rss => "New Freedom of Information requests",
                    # Authentication
                    :web => "To be told about any new requests",
                    :email => "Then you will be emailed whenever anyone makes a new FOI request",
                    :email_subject => "Confirm you want to be emailed about new requests",
                }
            elsif self.track_type == 'all_successful_requests'
                @params = {
                    # Website
                    :set_title => "How would you like to be told when any request succeeds?",
                    :list_description => "any <a href=\"/list/successful\">successful requests</a>",
                    :verb_on_page => "Be told when any request succeeds",
                    :verb_on_page_already => "being told when any request succeeds",
                    # Email
                    :title_in_email => "Successful Freedom of Information requests",
                    :title_in_rss => "Successful Freedom of Information requests",
                    # Authentication
                    :web => "To be told about any successful requests",
                    :email => "Then you will be emailed whenever an FOI request succeeds",
                    :email_subject => "Confirm you want to be emailed when an FOI request succeeds",
                }
            elsif self.track_type == 'public_body_updates'
                @params = {
                    # Website
                    :set_title => "How would you like to be told about new requests to the public authority '" + CGI.escapeHTML(self.public_body.name) + "'?",
                    :list_description => "'<a href=\"/body/" + CGI.escapeHTML(self.public_body.url_name) + "\">" + CGI.escapeHTML(self.public_body.name) + "</a>', a public authority", # XXX yeuch, sometimes I just want to call view helpers from the model, sorry! can't work out how 
                    :verb_on_page => "Be told about new requests to this public authority",
                    :verb_on_page_already => "being told about new requests to this public authority",
                    # Email
                    :title_in_email => "New FOI requests to '" + self.public_body.name + "'",
                    :title_in_rss => "New FOI requests to '" + self.public_body.name + "'",
                    # Authentication
                    :web => "To be told about new requests to the public authority '" + CGI.escapeHTML(self.public_body.name) + "'",
                    :email => "Then you will be emailed whenever someone requests something from '" + CGI.escapeHTML(self.public_body.name) + "'.",
                    :email_subject => "Confirm you want to be told about new requests to '" + CGI.escapeHTML(self.public_body.name) + "'",
                }
            elsif self.track_type == 'user_updates'
                @params = {
                    # Website
                    :set_title => "How would you like track the person '" + CGI.escapeHTML(self.tracked_user.name) + "'?",
                    :list_description => "'<a href=\"/user/" + CGI.escapeHTML(self.tracked_user.url_name) + "\">" + CGI.escapeHTML(self.tracked_user.name) + "</a>', a person", # XXX yeuch, sometimes I just want to call view helpers from the model, sorry! can't work out how 
                    :verb_on_page => "Be told about new requests by this person",
                    :verb_on_page_already => "being told about new requests by this person",
                    # Email
                    :title_in_email => "New FOI requests by '" + self.tracked_user.name + "'",
                    :title_in_rss => "New FOI requests by '" + self.tracked_user.name + "'",
                    # Authentication
                    :web => "To be told about new requests by '" + CGI.escapeHTML(self.tracked_user.name) + "'",
                    :email => "Then you will be emailed whenever '" + CGI.escapeHTML(self.tracked_user.name) + "' requests something",
                    :email_subject => "Confirm you want to be told about new requests by '" + CGI.escapeHTML(self.tracked_user.name) + "'",
                }
            elsif self.track_type == 'search_query'
                @params = {
                    # Website
                    :set_title => "How would you like to be updated about new requests and responses matching '" + CGI.escapeHTML(self.track_query) + "'?",
                    :list_description => "'<a href=\"/search/" + CGI.escapeHTML(self.track_query) + "/newest\">" + CGI.escapeHTML(self.track_query) + "</a>' in new requests/responses", # XXX yeuch, sometimes I just want to call view helpers from the model, sorry! can't work out how 
                    :verb_on_page => "Track new requests and responses matching '" + CGI.escapeHTML(self.track_query) + "'",
                    :verb_on_page_already => "tracking '" + CGI.escapeHTML(self.track_query) + "'",
                    # Email
                    :title_in_email => "Requests or responses matching '" + self.track_query + "'",
                    :title_in_rss => "Requests or responses matching '" + self.track_query + "'",
                    # Authentication
                    :web => "To follow requests and responses matching '" + CGI.escapeHTML(self.track_query) + "'",
                    :email => "Then you will be emailed whenever a new request or response matches '" + CGI.escapeHTML(self.track_query) + "'.",
                    :email_subject => "Confirm you want to be told about new requests or responses matching '" + CGI.escapeHTML(self.track_query) + "'",
                }
              else
                raise "unknown tracking type " + self.track_type
            end

            # for RSS sort by described date, as newest would give a date for
            # responses possibly days before description, so wouldn't appear at top
            # of list when description causes match.
            params[:feed_sortby] = 'described'
        end
        return @params
    end

    # When constructing a new track, use this to avoid duplicates / double posting
    def TrackThing.find_by_existing_track(tracking_user, track)
        if tracking_user.nil?
            return nil
        end
        return TrackThing.find(:first, :conditions => [ 'tracking_user_id = ? and track_query = ? and track_type = ?', tracking_user.id, track.track_query, track.track_type ] )
    end

    # List of people tracking same thing
    def TrackThing.find_tracking_people(track)
        return TrackThing.find(:all, :conditions => [ 'track_query = ? and track_type = ?', track.track_query, track.track_type ]).map { |t| t.tracking_user }
    end

end


