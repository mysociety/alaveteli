# == Schema Information
# Schema version: 29
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
#

# models/info_request.rb:
# A Freedom of Information request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: info_request.rb,v 1.37 2008-02-14 09:55:21 francis Exp $

require 'digest/sha1'

class InfoRequest < ActiveRecord::Base
    validates_presence_of :title, :message => "^Please enter a summary of your request"

    belongs_to :user
    #validates_presence_of :user_id # breaks during construction of new ones :(

    belongs_to :public_body
    validates_presence_of :public_body_id

    has_many :outgoing_messages
    has_many :incoming_messages
    has_many :info_request_events

    belongs_to :dsecribed_last_incoming_message_id

    # user described state
    validates_inclusion_of :described_state, :in => [ 
        'waiting_response',
        'waiting_clarification', 
        'rejected', 
        'successful', 
        'partially_successful'
    ]

    def after_initialize
        if self.described_state.nil?
            self.described_state = 'waiting_response'
        end
    end

public
    # Email which public body should use to respond to request. This is in
    # the format PREFIXrequest-ID-HASH@DOMAIN. Here ID is the id of the 
    # FOI request, and HASH is a signature for that id.
    def incoming_email
        return self.magic_email("request-")
    end
    def incoming_name_and_email
        return "GovernmentSpy <" + self.incoming_email + ">"
    end

    # Modified version of incoming_email to use in the envelope from, for
    # bounce messages.
    def envelope_email
        return self.magic_email("request-bounce-")
    end
    def envelope_name_and_email
        return "GovernmentSpy <" + self.envelope_email + ">"
    end

    # Return info request corresponding to an incoming email address, or nil if
    # none found. Checks the hash to ensure the email came from the public body -
    # only they are sent the email address with the has in it.
    def self.find_by_incoming_email(incoming_email)
        incoming_email =~ /request-(\d+)-([a-z0-9]+)/
        id = $1.to_i
        hash = $2

        return self.find_by_magic_email(id, hash)
    end

    def self.find_by_envelope_email(incoming_email)
        incoming_email =~ /request-bounce-(\d+)-([a-z0-9]+)/
        id = $1.to_i
        hash = $2

        return self.find_by_magic_email(id, hash)
    end

    # When constructing a new request, use this to check user hasn't double submitted.
    # XXX could have a date range here, so say only check last month's worth of new requests. If somebody is making
    # repeated requests, say once a quarter for time information, then might need to do that.
    # XXX this *should* also check outgoing message joined to is an initial
    # request (rather than follow up)
    def self.find_by_existing_request(title, public_body_id, body)
        return InfoRequest.find(:first, :conditions => [ 'title = ? and public_body_id = ? and outgoing_messages.body = ?', title, public_body_id, body ], :include => [ :outgoing_messages ] )
    end

    # A new incoming email to this request
    def receive(email, raw_email, is_bounce)
        incoming_message = IncomingMessage.new

        ActiveRecord::Base.transaction do
            incoming_message.raw_data = raw_email
            incoming_message.is_bounce = is_bounce
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
    end

    # Work out what the situation of the request is
    #   waiting_response
    #   waiting_response_overdue  # XXX calculated, should be cached for display?
    #   waiting_clarification
    #   rejected
    #   successful
    #   partially_successful
    def calculate_status
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
        # We use the last_sent_at date for each outgoing message, as fair
        # enough if the first email bounced or something and it got recent.
        # XXX if a second outgoing message is really a new request, then this
        # is no good. Likewise, a second outgoing message may contain
        # clarifications asked for by the public body, and so reset things.
        # Possibly just show 20 working days since the *last* message? Hmmm.
        earliest_sent = self.outgoing_messages.map { |om| om.last_sent_at }.min
        if earliest_sent.nil?
            raise "internal error, minimum last_sent_at for outgoing_messages is nil for request " + self.id.to_s + " outgoing messages count " + self.outgoing_messages.size.to_s
        end

        days_passed = 0
        response_required_by = earliest_sent
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

        # XXX and give until the end of that 20th working day
        
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
        return "FOI requests at " + self.public_body.short_name + " <" + self.recipient_email + ">"
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
    def get_last_response
        events = self.info_request_events.find(:all, :order => "created_at")
        events.reverse.each do |e|
            if e.event_type == 'response'
                id = e.params[:incoming_message_id].to_i
                return IncomingMessage.find(id)
            end
        end
        return nil
    end

    # Text from the the initial request, for use in summary display
    def initial_request_text
        if outgoing_messages.empty? # mainly for use with incomplete fixtures
            return ""
        end
        excerpt = outgoing_messages[0].body
        excerpt.sub!(/Dear .+,/, "")
        return excerpt
    end

    # Returns index of last event which is described or nil if none described.
    def index_of_last_described_event
        events = self.info_request_events.find(:all, :order => "created_at")
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
        events = self.info_request_events.find(:all, :order => "created_at")
        i = self.index_of_last_described_event
        if i.nil?
            return events
        else
            return events[i + 1, events.size]
        end
    end

    protected

    # Called by incoming_email and envelope_email
    def magic_email(prefix_part)
        raise "id required to make magic" if not self.id
        magic_email = MySociety::Config.get("INCOMING_EMAIL_PREFIX", "") 
        magic_email += prefix_part + self.id.to_s 
        magic_email += "-" + Digest::SHA1.hexdigest(self.id.to_s + MySociety::Config.get("INCOMING_EMAIL_SECRET", 'dummysecret'))[0,8]
        magic_email += "@" + MySociety::Config.get("INCOMING_EMAIL_DOMAIN", "localhost")
        return magic_email
    end

    # Called by find_by_incoming_email and find_by_envelope_email
    def self.find_by_magic_email(id, hash)
        expected_hash = Digest::SHA1.hexdigest(id.to_s + MySociety::Config.get("INCOMING_EMAIL_SECRET", 'dummysecret'))[0,8]
        #print "expected: " + expected_hash + "\nhash: " + hash + "\n"
        if hash != expected_hash
            return nil
        else
            return self.find(id)
        end
    end


end


