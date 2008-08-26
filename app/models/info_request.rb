# == Schema Information
# Schema version: 62
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
#  stop_new_responses   :boolean         default(false), not null
#  law_used             :string(255)     default("foi"), not null
#

# models/info_request.rb:
# A Freedom of Information request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: info_request.rb,v 1.131 2008-08-26 16:03:36 francis Exp $

require 'digest/sha1'
require File.join(File.dirname(__FILE__),'../../vendor/plugins/acts_as_xapian/lib/acts_as_xapian')

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
    has_many :comments, :order => 'created_at'

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

    validates_inclusion_of :law_used, :in => [ 
        'foi', # Freedom of Information Act
        'eir', # Environmental Information Regulations
    ]

    def after_initialize
        if self.described_state.nil?
            self.described_state = 'waiting_response'
        end
        # FOI or EIR?
        if not self.public_body.nil? and self.public_body.eir_only?
            self.law_used = 'eir'
        end
    end

    # Central function to do all searches
    # (Not really the right place to put it, but everything can get it here, and it
    # does *mainly* find info requests, via their events, so hey)
    def InfoRequest.full_search(models, query, order, ascending, collapse, per_page, page)
        offset = (page - 1) * per_page

        return ::ActsAsXapian::Search.new(
            models, query,
            :offset => offset, :limit => per_page,
            :sort_by_prefix => order,
            :sort_by_ascending => ascending,
            :collapse_by_prefix => collapse
        )
    end

    # For debugging
    def InfoRequest.profile_search(query)
        t = Time.now.usec
        for i in (1..10)
            t = Time.now.usec - t
            secs = t / 1000000.0
            STDOUT.write secs.to_s + " query " + i.to_s + "\n"
            results = InfoRequest.full_search([InfoRequestEvent], query, "created_at", false, nil, 25, 1).results
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
    # Remove spaces from ends (for when used in emails etc.)
    def title
        title = read_attribute(:title)
        if title
            title.strip!
        end
        return title
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
        if self.public_body.url_name == 'general_register_office'
            # without GQ in the subject, you just get an auto response
            self.law_used_full + ' request GQ - ' + self.title
        else
            self.law_used_full + ' request - ' + self.title
        end
    end
    def email_subject_followup
        if self.public_body.url_name == 'general_register_office'
            'Re: ' + self.law_used_full + ' request GQ - ' + self.title
        else
            self.law_used_full + ' request - ' + self.title
        end
    end

    # Two sorts of laws for requests, FOI or EIR 
    def law_used_full
        if self.law_used == 'foi'
            return "Freedom of Information"
        elsif self.law_used == 'eir'
            return "Environmental Information Regulations"
        else
            raise "Unknown law used '" + self.law_used + "'"
        end
    end
    def law_used_short
        if self.law_used == 'foi'
            return "FOI"
        elsif self.law_used == 'eir'
            return "EIR"
        else
            raise "Unknown law used '" + self.law_used + "'"
        end
    end
    def law_used_act
        if self.law_used == 'foi'
            return "Freedom of Information Act"
        elsif self.law_used == 'eir'
            return "Environmental Information Regulations"
        else
            raise "Unknown law used '" + self.law_used + "'"
        end
    end
    def law_used_with_a
        if self.law_used == 'foi'
            return "A Freedom of Information request"
        elsif self.law_used == 'eir'
            return "An Environmental Information Regulations request"
        else
            raise "Unknown law used '" + self.law_used + "'"
        end
    end


    # Return info request corresponding to an incoming email address, or nil if
    # none found. Checks the hash to ensure the email came from the public body -
    # only they are sent the email address with the has in it. (We don't check
    # the prefix and domain, as sometimes those change, or might be elided by
    # copying an email, and that doesn't matter)
    def InfoRequest.find_by_incoming_email(incoming_email)
        # Match case insensitively, FOI officers often write Request with capital R.
        incoming_email = incoming_email.downcase

        # The optional bounce- dates from when we used to have separate emails for the envelope from.
        # (that was abandoned because councils would send hand written responses to them, not just
        # bounce messages)
        incoming_email =~ /request-(?:bounce-)?(\d+)-([a-z0-9]+)/
        id = $1.to_i
        hash = $2

        if not hash.nil?
            # Convert l to 1, and o to 0. FOI officers quite often retype the
            # email address and make this kind of error.
            hash.gsub!(/l/, "1")
            hash.gsub!(/o/, "0")
        end

        return self.find_by_magic_email(id, hash)
    end

    # When constructing a new request, use this to check user hasn't double submitted.
    # XXX could have a date range here, so say only check last month's worth of new requests. If somebody is making
    # repeated requests, say once a quarter for time information, then might need to do that.
    # XXX this *should* also check outgoing message joined to is an initial
    # request (rather than follow up)
    def InfoRequest.find_by_existing_request(title, public_body_id, body)
        # XXX can add other databases here which have regexp_replace
        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            # Exclude spaces from the body comparison using regexp_replace
            return InfoRequest.find(:first, :conditions => [ "title = ? and public_body_id = ? and regexp_replace(outgoing_messages.body, '[[:space:]]', '', 'g') = regexp_replace(?, '[[:space:]]', '', 'g')", title, public_body_id, body ], :include => [ :outgoing_messages ] )
        else
            # For other databases (e.g. SQLite) not the end of the world being space-sensitive for this check
            return InfoRequest.find(:first, :conditions => [ "title = ? and public_body_id = ? and outgoing_messages.body = ?", title, public_body_id, body ], :include => [ :outgoing_messages ] )
        end
    end

    # A new incoming email to this request
    def receive(email, raw_email)
        # See if new responses are prevented for spam reasons
        if self.stop_new_responses
            RequestMailer.deliver_stopped_responses(self, email)
            return
        end

        # Otherwise log the message
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

    # An annotation (comment) is made
    def add_comment(body, user)
        comment = Comment.new

        ActiveRecord::Base.transaction do
            comment.body = body
            comment.user = user
            comment.comment_type = 'request'
            comment.info_request = self
            comment.save!

            self.log_event("comment", { :comment_id => comment.id })
            self.save!
        end

        return comment
    end

    # The "holding pen" is a special request which stores incoming emails whose
    # destination request is unknown.
    def InfoRequest.holding_pen_request
        ir = InfoRequest.find_by_url_title("holding_pen")
        if ir.nil?
            ir = InfoRequest.new(
                :user => User.internal_admin_user,
                :public_body => PublicBody.internal_admin_body,
                :title => 'Holding pen',
                :described_state => 'waiting_response',
                :awaiting_description => false,
                :prominence  => 'backpage'
            )
            om = OutgoingMessage.new({
                :status => 'ready',
                :message_type => 'initial_request',
                :body => 'This is the holding pen request. It shows responses that were sent to invalid addresses, and need moving to the correct request by an adminstrator.',
                :last_sent_at => Time.now()

            })
            ir.outgoing_messages << om
            om.info_request = ir
            ir.save!
            ir.log_event('sent', { :outgoing_message_id => om.id, :email => ir.public_body.request_email })
        end

        return ir
    end

    # change status, including for last event for later historical purposes
    def set_described_state(new_state)
        ActiveRecord::Base.transaction do
            self.awaiting_description = false
            last_event = self.get_last_event
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

    # Work out what the situation of the request is. In addition to values of
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

    # Fill in any missing event states for first response before a description
    # was made. i.e. We take the last described state in between two responses
    # (inclusive of earlier), and set it as calculated value for the earlier
    # response.
    def calculate_event_states
        curr_state = nil
        for event in self.info_request_events.reverse
            if not event.described_state.nil? and curr_state.nil?
                curr_state = event.described_state
                #STDERR.puts "curr_state " + curr_state
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
            elsif !curr_state.nil? && event.event_type == 'followup_sent' && !event.described_state.nil? && event.described_state == 'waiting_response'
                # followups can set the status to waiting response, which we don't
                # want to propogate to the response itself, as that might already be
                # set to waiting_clarification, which we want to know about.
                curr_state = nil
            end
        end
    end

    # Find last outgoing message which  was:
    # -- sent at all
    # -- OR the same message was resent
    # -- OR the public body requested clarification, and a follow up was sent
    def last_event_forming_initial_request
        last_sent = nil
        expecting_clarification = false
        for event in self.info_request_events
            if event.described_state == 'waiting_clarification'
                expecting_clarification = true
            end

            if [ 'sent', 'resent', 'followup_sent', 'followup_resent' ].include?(event.event_type)
                if last_sent.nil?
                    last_sent = event
                elsif event.event_type == 'resent'
                    last_sent = event
                elsif expecting_clarification and event.event_type == 'followup_sent'
                    # XXX this needs to cope with followup_resent, which it doesn't.
                    # Not really easy to do, and only affects cases where followups
                    # were resent after a clarification.
                    last_sent = event
                    expecting_clarification = false
                end
            end
        end
        if last_sent.nil?
            raise "internal error, date_response_required_by gets nil for request " + self.id.to_s + " outgoing messages count " + self.outgoing_messages.size.to_s + " all events: " + self.info_request_events.to_yaml
        end
        return last_sent
    end

    # Calculate date by end of which response is required by law.
    #
    #   ... "working day” means any day other than a Saturday, a Sunday, Christmas
    #   Day, Good Friday or a day which is a bank holiday under the [1971 c. 80.]
    #   Banking and Financial Dealings Act 1971 in any part of the United Kingdom.
    #
    # Freedom of Information Act 2000 section 10
    #
    # How do we cope with case where extra info was required from the requester
    # by the public body in order to fulfill the request, as per sections 1(3)
    # and 10(6b) ? For clarifications this is covered by
    # last_event_forming_initial_request. There may be more obscure
    # things, e.g. fees, not properly covered.
    def date_response_required_by
        # Find the ear
        last_sent = self.last_event_forming_initial_request
        last_sent_at = last_sent.outgoing_message.last_sent_at

        # Count forward 20 working days. We start with today (or if not a working day,
        # the next working day*) as "day zero". The first of the twenty full
        # working days is the next day. We return the date of the last of the twenty.
        #
        # * See this response for example of a public authority complaining when we got
        # that detail wrong: http://www.whatdotheyknow.com/request/364/response/1100
       
        # We have to skip non-working days at start to find day zero, so start at
        # day -1 and at yesterday, so we can do that.
        days_passed = -1 
        response_required_by = last_sent_at - 1.day
        # Now step forward into day zero, and then each of the 20 days.
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
        return self.public_body.request_email
    end
    def recipient_name_and_email
        return self.law_used_short + " requests at " + self.public_body.short_or_long_name + " <" + self.recipient_email + ">"
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
    def get_last_response_event
        info_request_event_id = get_last_response_event_id
        if info_request_event_id.nil?
            return nil
        else
            return InfoRequestEvent.find(info_request_event_id)
        end
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
            if [ 'sent', 'followup_sent' ].include?(e.event_type)
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

    # Get previous email sent to
    def get_previous_email_sent_to(info_request_event)
        last_email = nil
        for e in self.info_request_events
            if ((info_request_event.is_sent_sort? && e.is_sent_sort?) || (info_request_event.is_followup_sort? && e.is_followup_sort?)) && e.outgoing_message_id == info_request_event.outgoing_message_id
                if e.id == info_request_event.id
                    break
                end
                last_email = e.params[:email]
            end
        end
        return last_email
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
        self.user_info_request_sent_alerts.each { |a| a.destroy }
        self.info_request_events.each do |info_request_event| 
            info_request_event.track_things_sent_emails.each { |a| a.destroy }
            info_request_event.destroy
        end
        self.incoming_messages.each { |a| a.destroy }
        self.outgoing_messages.each { |a| a.destroy }
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


