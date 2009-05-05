# models/track_mailer.rb:
# Emails which go to users who are tracking things.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: track_mailer.rb,v 1.19 2009-05-05 08:52:41 louise Exp $

class TrackMailer < ApplicationMailer
    def event_digest(user, email_about_things)
        post_redirect = PostRedirect.new(
            :uri => main_url(user_url(user)) + "#email_subscriptions",
            :user_id => user.id)
        post_redirect.save!
        unsubscribe_url = confirm_url(:email_token => post_redirect.email_token)

        @from = contact_from_name_and_email
        # We let it return bounces for now, so we can manually kill the tracks that bounce so Yahoo
        # etc. don't decide we are spammers.
        #headers 'Return-Path' => blackhole_email, 'Reply-To' => @from # we don't care about bounces for tracks
        @recipients = user.name_and_email
        @subject = "Your WhatDoTheyKnow.com email alert"
        @body = { :user => user, :email_about_things => email_about_things, :unsubscribe_url => unsubscribe_url }
    end

    # Send email alerts for tracked things
    def self.alert_tracks
        now = Time.now()
        users = User.find(:all, :conditions => [ "last_daily_track_email < ?", now - 1.day ])
        for user in users
            #STDERR.puts "user " + user.url_name

            email_about_things = []
            track_things = TrackThing.find(:all, :conditions => [ "tracking_user_id = ? and track_medium = ?", user.id, 'email_daily' ])
            for track_thing in track_things
                #STDERR.puts "  track " + track_thing.track_query

                # What have we alerted on already?
                done_info_request_events = {}
                for t in track_thing.track_things_sent_emails
                    if not t.info_request_event_id.nil?
                        done_info_request_events[t.info_request_event_id] = 1
                    end
                end

                # Query for things in this track. We use described_at for the
                # ordering, so we catch anything new (before described), or
                # anything whose new status has been described.
                xapian_object = InfoRequest.full_search([InfoRequestEvent], track_thing.track_query, 'described_at', true, nil, 200, 1) 

                # Go through looking for unalerted things
                alert_results = []
                for result in xapian_object.results
                    if result[:model].class.to_s == "InfoRequestEvent"
                        if not done_info_request_events.include?(result[:model].id) and track_thing.created_at < result[:model].described_at
                            # OK alert this one
                            alert_results.push(result)
                        end
                    else
                        raise "need to add other types to TrackMailer.alert_tracks (unalerted)"
                    end
                end
                # If there were more alerts for this track, then store them
                if alert_results.size > 0 
                    email_about_things.push([track_thing, alert_results, xapian_object])
                end
            end

            # If we have anything to send, then send everything for the user in one mail
            if email_about_things.size > 0
                # Debugging
                STDERR.puts "sending email alert for user " + user.url_name
                for track_thing, alert_results, xapian_object in email_about_things
                   STDERR.puts "  tracking " + track_thing.track_query
                   for result in alert_results.reverse
                       STDERR.puts "    result " + result[:model].class.to_s + " id " + result[:model].id.to_s
                   end
                end

                # Send the email
                TrackMailer.deliver_event_digest(user, email_about_things)
            end

            # Record that we've now sent those alerts to that user
            for track_thing, alert_results in email_about_things
                for result in alert_results
                    track_things_sent_email = TrackThingsSentEmail.new
                    track_things_sent_email.track_thing_id = track_thing.id
                    if result[:model].class.to_s == "InfoRequestEvent"
                        track_things_sent_email.info_request_event_id = result[:model].id
                    else
                        raise "need to add other types to TrackMailer.alert_tracks (mark alerted)"
                    end
                    track_things_sent_email.save!
                end
            end
            user.last_daily_track_email = now
            user.no_xapian_reindex = true
            user.save!
        end
    end

end


