# == Schema Information
# Schema version: 49
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
#

# models/track_thing.rb:
# When somebody is getting alerts for something.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: track_thing.rb,v 1.1 2008-04-01 16:40:37 francis Exp $

class TrackThing < ActiveRecord::Base
    belongs_to :user, :foreign_key => 'tracking_user_id'
    validates_presence_of :track_query

    belongs_to :info_request
    belongs_to :public_body
    belongs_to :user, :foreign_key => 'tracked_user_id'

    validates_inclusion_of :track_medium, :in => [ 
        'email_daily', 
    ]

    attr_accessor :params

    def TrackThing.create_track_for_request(info_request)
        track_thing = TrackThing.new
        track_thing.info_request = info_request
        track_thing.params = {
            :title => "Track the request '" + CGI.escapeHTML(info_request.title) + "'",
            :feed_sortby => 'described',

            :web => "To follow updates to the request '" + CGI.escapeHTML(info_request.title) + "'",
            :email => "Then you will be emailed whenever the request '" + CGI.escapeHTML(info_request.title) + "' is updated.",
            :email_subject => "Confirm you want to follow updates to the request '" + CGI.escapeHTML(info_request.title) + "'",
        }
        track_thing.track_query = "request:" + info_request.url_title
        return track_thing
    end

end


