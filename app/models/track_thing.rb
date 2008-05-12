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
# $Id: track_thing.rb,v 1.15 2008-05-12 09:18:45 francis Exp $

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
                    # Other
                    :feed_sortby => 'described', # for RSS, as newest would give a date for responses possibly days before description
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
                    # Other
                    :feed_sortby => 'described', # for RSS, as newest would give a date for responses possibly days before description
                }
            elsif self.track_type == 'all_successful_requests'
                @params = {
                    # Website
                    :set_title => "How would you like to be told when any request succeeds?",
                    :list_description => "any <a href=\"/list\">successful requests</a>",
                    :verb_on_page => "Be told when any request succeeds",
                    :verb_on_page_already => "being told when any request succeeds",
                    # Email
                    :title_in_email => "Successful Freedom of Information requests",
                    :title_in_rss => "Successful Freedom of Information requests",
                    # Authentication
                    :web => "To be told about any successful requests",
                    :email => "Then you will be emailed whenever an FOI request succeeds",
                    :email_subject => "Confirm you want to be emailed when an FOI request succeeds",
                    # Other
                    :feed_sortby => 'described', # for RSS, as successfulest would give a date for responses possibly days before description
                }
             else
                raise "unknown tracking type " + self.track_type
            end
        end
        return @params
    end

    # When constructing a new track, use this to avoid duplicates / double posting
    def TrackThing.find_by_existing_track(tracking_user, track_query)
        if tracking_user.nil?
            return nil
        end
        return TrackThing.find(:first, :conditions => [ 'tracking_user_id = ? and track_query = ?', tracking_user.id, track_query ] )
    end

    # List of people tracking same thing
    def TrackThing.find_tracking_people(track_query)
        return TrackThing.find(:all, :conditions => [ 'track_query = ?', track_query ]).map { |t| t.tracking_user }
    end

end


