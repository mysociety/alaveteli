# == Schema Information
# Schema version: 52
#
# Table name: info_requests
#
#  id                   :integer         not null, primary key
#  title                :text            not null
#  user_id              :integer         not null
#  public_body_id       :integer         not null
#  created_at           :datetime        not null
#  updated_at           :datetime        not null
#  described_state      :string(255)     not null
#  awaiting_description :boolean         default(false), not null
#  prominence           :string(255)     default("normal"), not null
#  url_title            :text            not null
#

# models/info_request.rb:
# A Freedom of Information request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: info_request.rb,v 1.97 2008-04-29 16:23:31 francis Exp $

require 'digest/sha1'
require 'vendor/plugins/acts_as_xapian/lib/acts_as_xapian'

class InfoRequest < ActiveRecord::Base
    validates_presence_of :title, :message => "^Please enter a summary of your request"
    validates_format_of :title, :with => /[a-z]/, :message => "^Please write a summary with some text in it", :if => Proc.new { |info_request| !info_request.title.nil? && !info_request.title.empty? }

    belongs_to :user
    #validates_presence_of :user_id # breaks during construction of new ones :(

    belongs_to :public_body
    validates_presence_of :public_body_id

    has_many :outgoing_messages, :order => 'created_at'
    has_many :incoming_messages, :order => 'created_at'
    has_many :info_request_events, :order => 'created_at'
    has_many :user_info_request_sent_alerts
    has_many :track_things, :order => 'created_at desc'

    # user described state (also update in info_request_event, admin_request/edit.rhtml)
    validates_inclusion_of :described_state, :in => [ 
        'waiting_response',
        'waiting_clarification', 
        'not_held',
        'rejected', 
        'successful', 
        'partially_successful',
        'requires_admin'
    ]

    validates_inclusion_of :prominence, :in => [ 
        'normal', 
        'backpage',
    ]

    def after_initialize
        if self.described_state.nil?
            self.described_state = 'waiting_response'
        end
    end

    # Central function to do all searches
    # (Not really the right place to put it, but everything can get it here, and it
    # does *mainly* find info requests, via their events, so hey)
    def InfoRequest.full_search(query, order, ascending, per_page, page, html_highlight)
        # XXX handle order better
        # XXX html_highlight
        offset = (page - 1) * per_page
        return ::ActsAsXapian::Search.new(
            [InfoRequestEvent, PublicBody, User], query,
            :offset => offset, :limit => per_page,
            :sort_by_prefix => order,
            :sort_by_ascending => ascending, 
            :collapse_by_prefix => "request_collapse"
        )
    end

    # For debugging
    def InfoRequest.profile_search(query)
        t = Time.now.usec
        for i in (1..10)
            t = Time.now.usec - t
            secs = t / 1000000.0
            STDOUT.write secs.to_s + " query " + i.to_s + "\n"
            results = InfoRequest.full_search(query, "created_at", false, 25, 1, false).results
        end
    end

public
    # When name is changed, also change the url name
    def title=(title)
        write_attribute(:title, title)
        self.update_url_title
    end
    def update_url_title
        url_title = MySociety::Format.simplify_url_part(self.title, 32)
        # For request with same title as others, add on arbitary numeric identifier
        unique_url_title = url_title
        suffix_num = 2 # as there's already one without numeric suffix
        while not InfoRequest.find_by_url_title(unique_url_title, :conditions => self.id.nil? ? nil : ["id <> ?", self.id] ).nil?
            unique_url_title = url_title + "_" + suffix_num.to_s
            suffix_num = suffix_num + 1
        end
        write_attribute(:url_title, unique_url_title)
    end

    # Email which public body should use to respond to request. This is in
    # the format PREFIXrequest-ID-HASH@DOMAIN. Here ID is the id of the 
    # FOI request, and HASH is a signature for that id.
    def incoming_email
        return self.magic_email("request-")
    end
    def incoming_name_and_email
        return self.user.name + " <" + self.incoming_email + ">"
    end

    # Subject lines for emails about the request
    def email_subject_request
        'Freedom of Information request - ' + self.title
    end
    def email_subject_followup
        'Re: Freedom of Information request - ' + self.title
    end

    # Return info request corresponding to an incoming email address, or nil if
    # none found. Checks the hash to ensure the email came from the public body -
    # only they are sent the email address with the has in it. (We don't check
    # the prefix and domain, as sometimes those change, or might be elided by
    # copying an email, and that doesn't matter)
    def InfoRequest.find_by_incoming_email(incoming_email)
        # Match case insensitively
        incoming_email = incoming_email.downcase

        # The optional bounce- dates from when we used to have separate emails for the envelope from.
        # (that was abandoned because councils would send hand written responses to them, not just
        # bounce messages)
        incoming_email =~ /request-(?:bounce-)?(\d+)-([a-z0-9]+)/
        id = $1.to_i
        hash = $2

        return self.find_by_magic_email(id, hash)
    end

    # When constructing a new request, use this to check user hasn't double submitted.
    # XXX could have a date range here, so say only check last month's worth of new requests. If somebody is making
    # repeated requests, say once a quarter for time information, then might need to do that.
    # XXX this *should* also check outgoing message joined to is an initial
    # request (rather than follow up)
    def InfoRequest.find_by_existing_request(title, public_body_id, body)
        return InfoRequest.find(:first, :conditions => [ 'title = ? and public_body_id = ? and outgoing_messages.body = ?', title, public_body_id, body ], :include => [ :outgoing_messages ] )
    end

    # A new incoming email to this request
    def receive(email, raw_email)
        incoming_message = IncomingMessage.new

        ActiveRecord::Base.transaction do
            incoming_message.raw_data = raw_email
            incoming_message.info_request = self
            incoming_message.save!

            self.awaiting_description = true
            self.log_event("response", { :incoming_message_id => incoming_message.id })
            self.save!
        end

        RequestMailer.deliver_new_response(self, incoming_message)
    end

    # Change status - event id is of the most recent event at the change
    # XXX should probably check event id is last event here
    def set_described_state(new_state, event_id)
        ActiveRecord::Base.transaction do
            self.awaiting_description = false
            last_event = InfoRequestEvent.find(event_id)
            last_event.described_state = new_state
            self.described_state = new_state
            last_event.save!
            self.save!
        end

        self.calculate_event_states

        if new_state == 'requires_admin'
            RequestMailer.deliver_requires_admin(self)
        end
    end

    # Work out what the situation of the request is In addition to values of
    # self.described_state, can take these two values:
    #   waiting_classification
    #   waiting_response_overdue
    def calculate_status
        if self.awaiting_description
            return 'waiting_classification'
        end

        # See if response would be overdue 
        date_today = Time.now.strftime("%Y-%m-%d")
        date_response = date_response_required_by.strftime("%Y-%m-%d")
        if date_today > date_response
            overdue = true
        else
            overdue = false
        end

        if self.described_state == "waiting_response"
            if overdue
                return 'waiting_response_overdue'
            else
                return 'waiting_response'
            end
        end

        return self.described_state
    end

    # Fill in any missing event states for first response before a
    # description was made.
    def calculate_event_states
        curr_state = nil
        for event in self.info_request_events.reverse
            if not event.described_state.nil? and curr_state.nil?
                curr_state = event.described_state
            end

            if !curr_state.nil? && event.event_type == 'response' 
                if event.calculated_state != curr_state
                    event.calculated_state = curr_state
                    event.last_described_at = Time.now()
                    event.save!
                end
                if event.last_described_at.nil? # XXX actually maybe this isn't needed
                    event.last_described_at = Time.now()
                    event.save!
                end
                curr_state = nil
            end
        end
    end

    # Find last outgoing message which  was:
    # -- sent at all
    # -- OR the same message was resent
    # -- OR the public body requested clarification, and a follow up was sent
    def last_outgoing_message_forming_initial_request
        last_sent = nil
        expecting_clarification = false
        for event in self.info_request_events
            if event.described_state == 'waiting_clarification'
                expecting_clarification = true
            end

            if [ 'sent', 'resent', 'followup_sent' ].include?(event.event_type)
                outgoing_message = event.outgoing_message

                if last_sent.nil?
                    last_sent = outgoing_message
                elsif event.event_type == 'resent'
                    last_sent = outgoing_message
                elsif expecting_clarification and event.event_type == 'followup_sent'
                    last_sent = outgoing_message
                    expecting_clarification = false
                end
            end
        end
        if last_sent.nil?
            raise "internal error, date_response_required_by gets nil for request " + self.id.to_s + " outgoing messages count " + self.outgoing_messages.size.to_s + " all events: " + self.info_request_events.to_yaml
        end
        return last_sent
    end

    # Calculate date by which response is required by law.
    #
    #   ... "working day” means any day other than a Saturday, a Sunday, Christmas
    #   Day, Good Friday or a day which is a bank holiday under the [1971 c. 80.]
    #   Banking and Financial Dealings Act 1971 in any part of the United Kingdom.
    #
    # Freedom of Information Act 2000 section 10
    #
    # XXX how do we cope with case where extra info was required from the requester
    # by the public body in order to fulfill the request, as per sections 1(3) and 10(6b) ?
    def date_response_required_by
        # Find the ear
        last_sent = self.last_outgoing_message_forming_initial_request
        last_sent_at = last_sent.last_sent_at

        # Count forward 20 working days
        days_passed = 0
        response_required_by = last_sent_at
        while days_passed < 20
            response_required_by = response_required_by + 1.day
            if response_required_by.wday == 0 || response_required_by.wday == 6
                # not working day, as weekend
            elsif [
                # Union of holidays from these places:
                #   http://www.dti.gov.uk/employment/bank-public-holidays/
                #   http://www.scotland.gov.uk/Publications/2005/01/bankholidays

                '2007-11-30', '2007-12-25', '2007-12-26',

                '2008-01-01', '2008-01-02', '2008-03-17', '2008-03-21', '2008-03-24', '2008-05-05', 
                '2008-05-26', '2008-07-14', '2008-08-04', '2008-08-25', '2008-12-01', '2008-12-25', '2008-12-26',

                '2009-01-01', '2009-01-02', '2009-03-17', '2009-04-10', '2009-04-13', '2009-05-04',
                '2009-05-25', '2009-07-13', '2009-08-03', '2009-08-31', '2009-11-30', '2009-12-25', '2009-12-28',

                '2010-01-01', '2010-01-04', '2010-03-17', '2010-04-02', '2010-04-05', '2010-05-03', 
                '2010-05-31', '2010-07-12', '2010-08-02', '2010-08-30', '2010-11-30', '2010-12-27', '2010-12-28'


                ].include?(response_required_by.strftime('%Y-%m-%d'))
                # bank holiday
            else
                days_passed = days_passed + 1
            end
        end

        return response_required_by
    end

    # Where the initial request is sent to
    def recipient_email
        if MySociety::Config.getbool("STAGING_SITE", 1)
            return self.user.email
        else
            return self.public_body.request_email
        end
    end
    def recipient_name_and_email
        return "FOI requests at " + self.public_body.short_or_long_name + " <" + self.recipient_email + ">"
    end

    # History of some things that have happened
    def log_event(type, params)
        info_request_event = InfoRequestEvent.new
        info_request_event.event_type = type 
        info_request_event.params = params
        info_request_event.info_request = self
        info_request_event.save!
    end

    # The last response is the default one people might want to reply to
    def get_last_response_event_id
        for e in self.info_request_events.reverse
            if e.event_type == 'response'
                return e.id
            end
        end
        return nil
    end

    # The last response is the default one people might want to reply to
    def get_last_response
        event_id = self.get_last_response_event_id
        if event_id.nil?
            return nil
        end
        e = self.info_request_events.find(event_id)
        return e.incoming_message
    end

    # The last outgoing message
    def get_last_outgoing_event
        for e in self.info_request_events.reverse
            if e.event_type == 'sent' || e.event_type == 'resent' || e.event_type == 'followup_sent'
                return e
            end
        end
        return nil
    end

    # Text from the the initial request, for use in summary display
    def initial_request_text
        if outgoing_messages.empty? # mainly for use with incomplete fixtures
            return ""
        end
        excerpt = self.outgoing_messages[0].body_without_salutation
        return excerpt
    end

    # Returns index of last event which is described or nil if none described.
    def index_of_last_described_event
        events = self.info_request_events
        events.each_index do |i|
            revi = events.size - 1 - i 
            m = events[revi] 
            if not m.described_state.nil?
                return revi
            end
        end
        return nil
    end

    # Returns all the events which the user hasn't described yet - an empty array if all described.
    def events_needing_description
        events = self.info_request_events
        i = self.index_of_last_described_event
        if i.nil?
            return events
        else
            return events[i + 1, events.size]
        end
    end

    # Returns last event
    def get_last_event
        events = self.info_request_events
        if events.size == 0
            return nil
        else
            return events[-1]
        end
    end

    # Display version of status
    def display_status
        status = self.calculate_status
        if status == 'waiting_classification'
            "Awaiting classification."
        elsif status == 'waiting_response'
            "Awaiting response."
        elsif status == 'waiting_response_overdue'
            "Response overdue."
        elsif status == 'not_held'
            "Information not held."
        elsif status == 'rejected'
            "Rejected."
        elsif status == 'partially_successful'
            "Partially successful."
        elsif status == 'successful'
            "Successful."
        elsif status == 'waiting_clarification'
            "Waiting clarification."
        elsif status == 'requires_admin'
            "Unusual response."
        else
            raise "unknown status " + status
        end
    end

    # Completely delete this request and all objects depending on it
    def fully_destroy
        self.track_things.each do |track_thing|
            track_thing.track_things_sent_emails.each { |a| a.destroy }
            track_thing.destroy
        end
        self.incoming_messages.each { |a| a.destroy }
        self.outgoing_messages.each { |a| a.destroy }
        self.user_info_request_sent_alerts.each { |a| a.destroy }
        self.info_request_events.each { |a| a.destroy }
        self.destroy
    end

    # Called by incoming_email - and used to be called to generate separate
    # envelope from address until we abandoned it.
    def magic_email(prefix_part)
        raise "id required to make magic" if not self.id
        return InfoRequest.magic_email_for_id(prefix_part, self.id)
    end

    def InfoRequest.magic_email_for_id(prefix_part, id) 
        magic_email = MySociety::Config.get("INCOMING_EMAIL_PREFIX", "") 
        magic_email += prefix_part + id.to_s
        magic_email += "-" + Digest::SHA1.hexdigest(id.to_s + MySociety::Config.get("INCOMING_EMAIL_SECRET", 'dummysecret'))[0,8]
        magic_email += "@" + MySociety::Config.get("INCOMING_EMAIL_DOMAIN", "localhost")
        return magic_email
    end

    # Called by find_by_incoming_email - and used to be called by separate
    # function for envelope from address, until we abandoned it.
    def InfoRequest.find_by_magic_email(id, hash)
        expected_hash = Digest::SHA1.hexdigest(id.to_s + MySociety::Config.get("INCOMING_EMAIL_SECRET", 'dummysecret'))[0,8]
        #print "expected: " + expected_hash + "\nhash: " + hash + "\n"
        if hash != expected_hash
            return nil
        else
            begin
                return self.find(id)
            rescue ActiveRecord::RecordNotFound
                # so error email is sent to admin, rather than the exception sending weird
                # error to the public body.
                return nil
            end
        end
    end

end


