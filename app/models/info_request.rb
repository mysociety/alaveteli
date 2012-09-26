# == Schema Information
# Schema version: 20120919140404
#
# Table name: info_requests
#
#  id                        :integer         not null, primary key
#  title                     :text            not null
#  user_id                   :integer
#  public_body_id            :integer         not null
#  created_at                :datetime        not null
#  updated_at                :datetime        not null
#  described_state           :string(255)     not null
#  awaiting_description      :boolean         default(FALSE), not null
#  prominence                :string(255)     default("normal"), not null
#  url_title                 :text            not null
#  law_used                  :string(255)     default("foi"), not null
#  allow_new_responses_from  :string(255)     default("anybody"), not null
#  handle_rejected_responses :string(255)     default("bounce"), not null
#  idhash                    :string(255)     not null
#  external_user_name        :string(255)
#  external_url              :string(255)
#  attention_requested       :boolean         default(FALSE)
#  comments_allowed          :boolean         default(TRUE), not null
#

require 'digest/sha1'

class InfoRequest < ActiveRecord::Base
    include ActionView::Helpers::UrlHelper
    include ActionController::UrlWriter

    strip_attributes!

    validates_presence_of :title, :message => N_("Please enter a summary of your request")
    validates_format_of :title, :with => /[a-zA-Z]/, :message => N_("Please write a summary with some text in it"), :if => Proc.new { |info_request| !info_request.title.nil? && !info_request.title.empty? }

    belongs_to :user
    validate :must_be_internal_or_external

    belongs_to :public_body, :counter_cache => true
    validates_presence_of :public_body_id

    has_many :outgoing_messages, :order => 'created_at'
    has_many :incoming_messages, :order => 'created_at'
    has_many :info_request_events, :order => 'created_at'
    has_many :user_info_request_sent_alerts
    has_many :track_things, :order => 'created_at desc'
    has_many :comments, :order => 'created_at'
    has_many :censor_rules, :order => 'created_at desc'
    has_many :exim_logs, :order => 'exim_log_done_id'

    has_tag_string

    # user described state (also update in info_request_event, admin_request/edit.rhtml)
    validate :must_be_valid_state

    validates_inclusion_of :prominence, :in => [
        'normal',
        'backpage',
        'hidden',
        'requester_only'
    ]

    validates_inclusion_of :law_used, :in => [
        'foi', # Freedom of Information Act
        'eir', # Environmental Information Regulations
    ]

    # who can send new responses
    validates_inclusion_of :allow_new_responses_from, :in => [
        'anybody', # anyone who knows the request email address
        'authority_only', # only people from authority domains
        'nobody'
    ]
    # what to do with refused new responses
    validates_inclusion_of :handle_rejected_responses, :in => [
        'bounce', # return them to sender
        'holding_pen', # put them in the holding pen
        'blackhole' # just dump them
    ]

    def self.enumerate_states
        states = [
        'waiting_response',
        'waiting_clarification',
        'gone_postal',
        'not_held',
        'rejected', # this is called 'refused' in UK FOI law and the user interface, but 'rejected' internally for historic reasons
        'successful',
        'partially_successful',
        'internal_review',
        'error_message',
        'requires_admin',
        'user_withdrawn',
        'attention_requested',
        'vexatious',
        'not_foi'
        ]
        if @@custom_states_loaded
            states += InfoRequest.theme_extra_states
        end
        states
    end

    def must_be_valid_state
        errors.add(:described_state, "is not a valid state") if
            !InfoRequest.enumerate_states.include? described_state
    end

    # The request must either be internal, in which case it has
    # a foreign key reference to a User object and no external_url or external_user_name,
    # or else be external in which case it has no user_id but does have an external_url,
    # and may optionally also have an external_user_name.
    #
    # External requests are requests that have been added using the API, whereas internal
    # requests are requests made using the site.
    def must_be_internal_or_external
        # We must permit user_id and external_user_name both to be nil, because the system
        # allows a request to be created by a non-logged-in user.
        if !user_id.nil?
            errors.add(:external_user_name, "must be null for an internal request") if !external_user_name.nil?
            errors.add(:external_url, "must be null for an internal request") if !external_url.nil?
        end
    end

    def is_external?
        !external_url.nil?
    end

    def user_name
        is_external? ? external_user_name : user.name
    end

    def user_name_slug
        if is_external?
            if external_user_name.nil?
                fake_slug = "anonymous"
            else
                fake_slug = external_user_name.parameterize
            end
            (public_body.url_name || "") + "_" + fake_slug
        else
            user.url_name
        end
    end

    @@custom_states_loaded = false
    begin
        if ENV["RAILS_ENV"] != "test"
            require 'customstates'
            include InfoRequestCustomStates
            @@custom_states_loaded = true
        end
    rescue MissingSourceFile, NameError
    end

    # only check on create, so existing models with mixed case are allowed
    def validate_on_create
        if !self.title.nil? && !MySociety::Validate.uses_mixed_capitals(self.title, 10)
            errors.add(:title, _('Please write the summary using a mixture of capital and lower case letters. This makes it easier for others to read.'))
        end
        if !self.title.nil? && title.size > 200
            errors.add(:title, _('Please keep the summary short, like in the subject of an email. You can use a phrase, rather than a full sentence.'))
        end
        if !self.title.nil? && self.title =~ /^(FOI|Freedom of Information)\s*requests?$/i
            errors.add(:title, _('Please describe more what the request is about in the subject. There is no need to say it is an FOI request, we add that on anyway.'))
        end
    end

    OLD_AGE_IN_DAYS = 21.days

    def after_initialize
        if self.described_state.nil?
            self.described_state = 'waiting_response'
        end
        # FOI or EIR?
        if !self.public_body.nil? && self.public_body.eir_only?
            self.law_used = 'eir'
        end
    end

    def visible_comments
        self.comments.find(:all, :conditions => 'visible')
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

    # If the URL name has changed, then all request: queries will break unless
    # we update index for every event. Also reindex if prominence changes.
    after_update :reindex_some_request_events
    def reindex_some_request_events
        if self.changes.include?('url_title') || self.changes.include?('prominence') || self.changes.include?('user_id')
            self.reindex_request_events
        end
    end
    def reindex_request_events
        for info_request_event in self.info_request_events
            info_request_event.xapian_mark_needs_index
        end
    end
    # Force reindex when tag string changes
    alias_method :orig_tag_string=, :tag_string=
    def tag_string=(tag_string)
        ret = self.orig_tag_string=(tag_string)
        reindex_request_events
        return ret
    end

    # Removes anything cached about the object in the database, and saves
    def clear_in_database_caches!
        for incoming_message in self.incoming_messages
            incoming_message.clear_in_database_caches!
        end
    end

    # For debugging
    def InfoRequest.profile_search(query)
        t = Time.now.usec
        for i in (1..10)
            t = Time.now.usec - t
            secs = t / 1000000.0
            STDOUT.write secs.to_s + " query " + i.to_s + "\n"
            results = InfoRequest.full_search([InfoRequestEvent], query, "created_at", true, nil, 25, 1).results
        end
    end

public
    # When name is changed, also change the url name
    def title=(title)
        write_attribute(:title, title)
        self.update_url_title
    end
    def update_url_title
        url_title = MySociety::Format.simplify_url_part(self.title, 'request', 32)
        # For request with same title as others, add on arbitary numeric identifier
        unique_url_title = url_title
        suffix_num = 2 # as there's already one without numeric suffix
        while not InfoRequest.find_by_url_title(unique_url_title,
            :conditions => self.id.nil? ? nil : ["id <> ?", self.id]
        ).nil?
            unique_url_title = url_title + "_" + suffix_num.to_s
            suffix_num = suffix_num + 1
        end
        write_attribute(:url_title, unique_url_title)
    end
    # Remove spaces from ends (for when used in emails etc.)
    # Needed for legacy reasons, even though we call strip_attributes now
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
        return TMail::Address.address_from_name_and_email(self.user_name, self.incoming_email).to_s
    end

    # Subject lines for emails about the request
    def email_subject_request
        # XXX pull out this general_register_office specialisation
        # into some sort of separate jurisdiction dependent file
        if self.public_body.url_name == 'general_register_office'
            # without GQ in the subject, you just get an auto response
            _('{{law_used_full}} request GQ - {{title}}',:law_used_full=>self.law_used_full,:title=>self.title)
        else
            _('{{law_used_full}} request - {{title}}',:law_used_full=>self.law_used_full,:title=>self.title)
        end
    end
    def email_subject_followup(incoming_message = nil)
        if incoming_message.nil? || !incoming_message.valid_to_reply_to?
            'Re: ' + self.email_subject_request
        else
            if incoming_message.subject.match(/^Re:/i)
                incoming_message.subject
            else
                'Re: ' + incoming_message.subject
            end
        end
    end

    # Two sorts of laws for requests, FOI or EIR
    def law_used_full
        if self.law_used == 'foi'
            return _("Freedom of Information")
        elsif self.law_used == 'eir'
            return _("Environmental Information Regulations")
        else
            raise "Unknown law used '" + self.law_used + "'"
        end
    end
    def law_used_short
        if self.law_used == 'foi'
            return _("FOI")
        elsif self.law_used == 'eir'
            return _("EIR")
        else
            raise "Unknown law used '" + self.law_used + "'"
        end
    end
    def law_used_act
        if self.law_used == 'foi'
            return _("Freedom of Information Act")
        elsif self.law_used == 'eir'
            return _("Environmental Information Regulations")
        else
            raise "Unknown law used '" + self.law_used + "'"
        end
    end
    def law_used_with_a
        if self.law_used == 'foi'
            return _("A Freedom of Information request")
        elsif self.law_used == 'eir'
            return _("An Environmental Information Regulations request")
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
        id, hash = InfoRequest._extract_id_hash_from_email(incoming_email)
        return self.find_by_magic_email(id, hash)
    end

    # Return list of info requests which *might* be right given email address
    # e.g. For the id-hash email addresses, don't match the hash.
    def InfoRequest.guess_by_incoming_email(incoming_message)
        guesses = []
        # 1. Try to guess based on the email address(es)
        addresses =
            (incoming_message.mail.to || []) +
            (incoming_message.mail.cc || []) +
            (incoming_message.mail.envelope_to || [])
        addresses.uniq!
        for address in addresses
            id, hash = InfoRequest._extract_id_hash_from_email(address)
            guesses.push(InfoRequest.find_by_id(id))
            guesses.push(InfoRequest.find_by_idhash(hash))
        end
        return guesses.select{|x| !x.nil?}.uniq
    end

    # Internal function used by find_by_magic_email and guess_by_incoming_email
    def InfoRequest._extract_id_hash_from_email(incoming_email)
        # Match case insensitively, FOI officers often write Request with capital R.
        incoming_email = incoming_email.downcase

        # The optional bounce- dates from when we used to have separate emails for the envelope from.
        # (that was abandoned because councils would send hand written responses to them, not just
        # bounce messages)
        incoming_email =~ /request-(?:bounce-)?([a-z0-9]+)-([a-z0-9]+)/
        id = $1.to_i
        hash = $2

        if not hash.nil?
            # Convert l to 1, and o to 0. FOI officers quite often retype the
            # email address and make this kind of error.
            hash.gsub!(/l/, "1")
            hash.gsub!(/o/, "0")
        end

        return [id, hash]
    end


    # When constructing a new request, use this to check user hasn't double submitted.
    # XXX could have a date range here, so say only check last month's worth of new requests. If somebody is making
    # repeated requests, say once a quarter for time information, then might need to do that.
    # XXX this *should* also check outgoing message joined to is an initial
    # request (rather than follow up)
    def InfoRequest.find_by_existing_request(title, public_body_id, body)
        return InfoRequest.find(:first, :conditions => [ "title = ? and public_body_id = ? and outgoing_messages.body = ?", title, public_body_id, body ], :include => [ :outgoing_messages ] )
    end

    def find_existing_outgoing_message(body)
        # XXX can add other databases here which have regexp_replace
        if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
            # Exclude spaces from the body comparison using regexp_replace
            return self.outgoing_messages.find(:first, :conditions => [ "regexp_replace(outgoing_messages.body, '[[:space:]]', '', 'g') = regexp_replace(?, '[[:space:]]', '', 'g')", body ])
        else
            # For other databases (e.g. SQLite) not the end of the world being space-sensitive for this check
            return self.outgoing_messages.find(:first, :conditions => [ "outgoing_messages.body = ?", body ])
        end
    end

    # Has this email already been received here? Based just on message id.
    def already_received?(email, raw_email_data)
        message_id = email.message_id
        if message_id.nil?
            raise "No message id for this message"
        end

        for im in self.incoming_messages
            other_message_id = im.mail.message_id
            if message_id == other_message_id
                return true
            end
        end

        return false
    end

    # A new incoming email to this request
    def receive(email, raw_email_data, override_stop_new_responses = false, rejected_reason = "")
        if !override_stop_new_responses
            allow = nil
            reason = nil
            # See if new responses are prevented for spam reasons
            if self.allow_new_responses_from == 'nobody'
                allow = false
                reason = _('This request has been set by an administrator to "allow new responses from nobody"')
            elsif self.allow_new_responses_from == 'anybody'
                allow = true
            elsif self.allow_new_responses_from == 'authority_only'
                if email.from_addrs.nil? || email.from_addrs.size == 0
                    allow = false
                    reason = _('Only the authority can reply to this request, but there is no "From" address to check against')
                else
                    sender_email = email.from_addrs[0].spec
                    sender_domain = PublicBody.extract_domain_from_email(sender_email)
                    reason = _("Only the authority can reply to this request, and I don't recognise the address this reply was sent from")
                    allow = false
                    # Allow any domain that has already sent reply
                    for row in self.who_can_followup_to
                        request_domain = PublicBody.extract_domain_from_email(row[1])
                        if request_domain == sender_domain
                            allow = true
                        end
                    end
                end
            else
                raise "Unknown allow_new_responses_from '" + self.allow_new_responses_from + "'"
            end

            if !allow
                if self.handle_rejected_responses == 'bounce'
                    RequestMailer.deliver_stopped_responses(self, email, raw_email_data) if !is_external?
                elsif self.handle_rejected_responses == 'holding_pen'
                    InfoRequest.holding_pen_request.receive(email, raw_email_data, false, reason)
                elsif self.handle_rejected_responses == 'blackhole'
                    # do nothing - just lose the message (Note: a copy will be
                    # in the backup mailbox if the server is configured to send
                    # new incoming messages there as well as this script)
                else
                    raise "Unknown handle_rejected_responses '" + self.handle_rejected_responses + "'"
                end
                return
            end
        end

        # Otherwise log the message
        incoming_message = IncomingMessage.new

        ActiveRecord::Base.transaction do
            raw_email = RawEmail.new
            incoming_message.raw_email = raw_email
            incoming_message.info_request = self
            incoming_message.save!
            raw_email.data = raw_email_data
            raw_email.save!

            self.awaiting_description = true
            params = { :incoming_message_id => incoming_message.id }
            if !rejected_reason.empty?
                params[:rejected_reason] = rejected_reason
            end
            self.log_event("response", params)
            self.save!
        end
        self.info_request_events.each { |event| event.xapian_mark_needs_index } # for the "waiting_classification" index
        RequestMailer.deliver_new_response(self, incoming_message) if !is_external?
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
                :last_sent_at => Time.now(),
                :what_doing => 'normal_sort'

            })
            ir.outgoing_messages << om
            om.info_request = ir
            ir.save!
            ir.log_event('sent', { :outgoing_message_id => om.id, :email => ir.public_body.request_email })
        end

        return ir
    end

    # states which require administrator action (hence email administrators
    # when they are entered, and offer state change dialog to them)
    def InfoRequest.requires_admin_states
        return ['requires_admin', 'error_message', 'attention_requested']
    end

    def requires_admin?
        return true if InfoRequest.requires_admin_states.include?(described_state)
        return false
    end

    # change status, including for last event for later historical purposes
    def set_described_state(new_state, set_by = nil)
        ActiveRecord::Base.transaction do
            self.awaiting_description = false
            last_event = self.get_last_event
            last_event.described_state = new_state
            self.described_state = new_state
            last_event.save!
            self.save!
        end

        self.calculate_event_states

        if self.requires_admin?
            # Check there is someone to send the message "from"
            if !set_by.nil? || !self.user.nil?
                RequestMailer.deliver_requires_admin(self, set_by)
            end
        end
    end

    # Work out what the situation of the request is. In addition to values of
    # self.described_state, can take these two values:
    #   waiting_classification
    #   waiting_response_overdue
    #   waiting_response_very_overdue
    def calculate_status
        if @@custom_states_loaded
            return self.theme_calculate_status
        else
            self.base_calculate_status
        end
    end

    def base_calculate_status
        return 'waiting_classification' if self.awaiting_description
        return described_state unless self.described_state == "waiting_response"
        # Compare by date, so only overdue on next day, not if 1 second late
        return 'waiting_response_very_overdue' if
            Time.now.strftime("%Y-%m-%d") > self.date_very_overdue_after.strftime("%Y-%m-%d")
        return 'waiting_response_overdue' if
            Time.now.strftime("%Y-%m-%d") > self.date_response_required_by.strftime("%Y-%m-%d")
        return 'waiting_response'
    end

    # Fill in any missing event states for first response before a description
    # was made. i.e. We take the last described state in between two responses
    # (inclusive of earlier), and set it as calculated value for the earlier
    # response.
    def calculate_event_states
        curr_state = nil
        for event in self.info_request_events.reverse
            event.xapian_mark_needs_index  # we need to reindex all events in order to update their latest_* terms
            if curr_state.nil?
                if !event.described_state.nil?
                    curr_state = event.described_state
                end
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
            elsif !curr_state.nil? && (event.event_type == 'followup_sent' || event.event_type == 'sent') && !event.described_state.nil? && (event.described_state == 'waiting_response' || event.described_state == 'internal_review')
                # Followups can set the status to waiting response / internal
                # review. Initial requests ('sent') set the status to waiting response.

                # We want to store that in calculated_state state so it gets
                # indexed.
                if event.calculated_state != event.described_state
                    event.calculated_state = event.described_state
                    event.last_described_at = Time.now()
                    event.save!
                end

                # And we don't want to propogate it to the response itself,
                # as that might already be set to waiting_clarification / a
                # success status, which we want to know about.
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
            raise "internal error, last_event_forming_initial_request gets nil for request " + self.id.to_s + " outgoing messages count " + self.outgoing_messages.size.to_s + " all events: " + self.info_request_events.to_yaml
        end
        return last_sent
    end

    # The last time that the initial request was sent/resent
    def date_initial_request_last_sent_at
        last_sent = last_event_forming_initial_request
        return last_sent.outgoing_message.last_sent_at
    end
    # How do we cope with case where extra info was required from the requester
    # by the public body in order to fulfill the request, as per sections 1(3)
    # and 10(6b) ? For clarifications this is covered by
    # last_event_forming_initial_request. There may be more obscure
    # things, e.g. fees, not properly covered.
    def date_response_required_by
        Holiday.due_date_from(self.date_initial_request_last_sent_at, Configuration::reply_late_after_days, Configuration::working_or_calendar_days)
    end
    # This is a long stop - even with UK public interest test extensions, 40
    # days is a very long time.
    def date_very_overdue_after
        last_sent = last_event_forming_initial_request
        if self.public_body.is_school?
            # schools have 60 working days maximum (even over a long holiday)
            Holiday.due_date_from(self.date_initial_request_last_sent_at, Configuration::special_reply_very_late_after_days, Configuration::working_or_calendar_days)
        else
            # public interest test ICO guidance gives 40 working maximum
            Holiday.due_date_from(self.date_initial_request_last_sent_at, Configuration::reply_very_late_after_days, Configuration::working_or_calendar_days)
        end
    end

    # Where the initial request is sent to
    def recipient_email
        return self.public_body.request_email
    end
    def recipient_email_valid_for_followup?
        return self.public_body.is_followupable?
    end
    def recipient_name_and_email
        return TMail::Address.address_from_name_and_email(
            _("{{law_used}} requests at {{public_body}}",
                :law_used => self.law_used_short,
                :public_body => self.public_body.short_or_long_name),
            self.recipient_email).to_s
    end

    # History of some things that have happened
    def log_event(type, params)
        self.info_request_events.create!(:event_type => type, :params => params)
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
    def get_last_response_event
        for e in self.info_request_events.reverse
            if e.event_type == 'response'
                return e
            end
        end
        return nil
    end
    def get_last_response
        last_response_event = self.get_last_response_event
        if last_response_event.nil?
            return nil
        else
            return last_response_event.incoming_message
        end
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
        excerpt = self.outgoing_messages[0].get_text_for_indexing
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

    def last_event_id_needing_description
        last_event = events_needing_description[-1]
        last_event.nil? ? 0 : last_event.id
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
    def InfoRequest.get_status_description(status)
        if status == 'waiting_classification'
            _("Awaiting classification.")
        elsif status == 'waiting_response'
            _("Awaiting response.")
        elsif status == 'waiting_response_overdue'
            _("Delayed.")
        elsif status == 'waiting_response_very_overdue'
            _("Long overdue.")
        elsif status == 'not_held'
            _("Information not held.")
        elsif status == 'rejected'
            _("Refused.")
        elsif status == 'partially_successful'
            _("Partially successful.")
        elsif status == 'successful'
            _("Successful.")
        elsif status == 'waiting_clarification'
            _("Waiting clarification.")
        elsif status == 'gone_postal'
            _("Handled by post.")
        elsif status == 'internal_review'
            _("Awaiting internal review.")
        elsif status == 'error_message'
            _("Delivery error")
        elsif status == 'requires_admin'
            _("Unusual response.")
        elsif status == 'attention_requested'
            _("Reported for administrator attention.")
        elsif status == 'user_withdrawn'
            _("Withdrawn by the requester.")
        elsif status == 'vexatious'
            _("Considered by administrators as vexatious and hidden from site.")
        elsif status == 'not_foi'
            _("Considered by administrators as not an FOI request and hidden from site.")
        else
            begin
                return self.theme_display_status(status)
            rescue NoMethodError
                raise _("unknown status ") + status
            end
        end
    end

    def display_status
        InfoRequest.get_status_description(self.calculate_status)
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
        self.exim_logs.each do |exim_log|
            exim_log.destroy
        end
        self.outgoing_messages.each { |a| a.destroy }
        self.incoming_messages.each { |a| a.destroy }
        self.destroy
    end

    # Called by incoming_email - and used to be called to generate separate
    # envelope from address until we abandoned it.
    def magic_email(prefix_part)
        raise "id required to make magic" if not self.id
        return InfoRequest.magic_email_for_id(prefix_part, self.id)
    end

    def InfoRequest.magic_email_for_id(prefix_part, id)
        magic_email = Configuration::incoming_email_prefix
        magic_email += prefix_part + id.to_s
        magic_email += "-" + InfoRequest.hash_from_id(id)
        magic_email += "@" + Configuration::incoming_email_domain
        return magic_email
    end

    before_validation :compute_idhash

    def compute_idhash
        self.idhash = InfoRequest.hash_from_id(self.id)
    end

    def InfoRequest.hash_from_id(id)
        return Digest::SHA1.hexdigest(id.to_s + Configuration::incoming_email_secret)[0,8]
    end

    # Called by find_by_incoming_email - and used to be called by separate
    # function for envelope from address, until we abandoned it.
    def InfoRequest.find_by_magic_email(id, hash)
        expected_hash = InfoRequest.hash_from_id(id)
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

    # Used to find when event last changed
    def InfoRequest.last_event_time_clause(event_type=nil)
        event_type_clause = ''
        event_type_clause = " AND info_request_events.event_type = '#{event_type}'" if event_type
        "(SELECT created_at
          FROM info_request_events
          WHERE info_request_events.info_request_id = info_requests.id
          #{event_type_clause}
          ORDER BY created_at desc
          LIMIT 1)"
    end

    def InfoRequest.old_unclassified_params(extra_params, include_last_response_time=false)
        last_response_created_at = last_event_time_clause('response')
        age = extra_params[:age_in_days] ? extra_params[:age_in_days].days : OLD_AGE_IN_DAYS
        params = { :conditions => ["awaiting_description = ?
                                    AND #{last_response_created_at} < ?
                                    AND url_title != 'holding_pen'
                                    AND user_id IS NOT NULL",
                                    true, Time.now() - age] }
        if include_last_response_time
            params[:select] = "*, #{last_response_created_at} AS last_response_time"
            params[:order] = 'last_response_time'
        end
        return params
    end

    def InfoRequest.count_old_unclassified(extra_params={})
        params = old_unclassified_params(extra_params)
        count(:all, params)
    end

    def InfoRequest.get_random_old_unclassified(limit)
        params = old_unclassified_params({})
        params[:limit] = limit
        params[:order] = "random()"
        find(:all, params)
    end

    def InfoRequest.find_old_unclassified(extra_params={})
        params = old_unclassified_params(extra_params, include_last_response_time=true)
        [:limit, :include, :offset].each do |extra|
            params[extra] = extra_params[extra] if extra_params[extra]
        end
        if extra_params[:order]
            params[:order] = extra_params[:order]
            params.delete(:select)
        end
        if extra_params[:conditions]
            condition_string = extra_params[:conditions].shift
            params[:conditions][0] += " AND #{condition_string}"
            params[:conditions] += extra_params[:conditions]
        end
        find(:all, params)
    end

    def is_old_unclassified?
        return false if is_external?
        return false if !awaiting_description
        return false if url_title == 'holding_pen'
        last_response_event = get_last_response_event
        return false unless last_response_event
        return false if last_response_event.created_at >= Time.now - OLD_AGE_IN_DAYS
        return true
    end

    # List of incoming messages to followup, by unique email
    def who_can_followup_to(skip_message = nil)
        ret = []
        done = {}
        for incoming_message in self.incoming_messages.reverse
            if incoming_message == skip_message
                next
            end
            incoming_message.safe_mail_from

            email = OutgoingMailer.email_for_followup(self, incoming_message)
            name = OutgoingMailer.name_for_followup(self, incoming_message)

            if !done.include?(email.downcase)
                ret = ret + [[name, email, incoming_message.id]]
            end
            done[email.downcase] = 1
        end

        if !done.include?(self.public_body.request_email.downcase)
            ret = ret + [[self.public_body.name, self.public_body.request_email, nil]]
        end
        done[self.public_body.request_email.downcase] = 1

        return ret.reverse
    end

    # Get the list of censor rules that apply to this request
    def applicable_censor_rules
        applicable_rules = [self.censor_rules, self.public_body.censor_rules, CensorRule.global.all]
        if self.user && !self.user.censor_rules.empty?
            applicable_rules << self.user.censor_rules
        end
        return applicable_rules.flatten
    end

    # Call groups of censor rules
    def apply_censor_rules_to_text!(text)
        self.applicable_censor_rules.each do |censor_rule|
            censor_rule.apply_to_text!(text)
        end
        return text
    end

    def apply_censor_rules_to_binary!(binary)
        self.applicable_censor_rules.each do |censor_rule|
            censor_rule.apply_to_binary!(binary)
        end
        return binary
    end

    def is_owning_user?(user)
        !user.nil? && (user.id == user_id || user.owns_every_request?)
    end
    def is_actual_owning_user?(user)
        !user.nil? && user.id == user_id
    end

    def user_can_view?(user)
        if self.prominence == 'hidden'
            return User.view_hidden_requests?(user)
        end
        if self.prominence == 'requester_only'
            return self.is_owning_user?(user)
        end
        return true
    end

    # Is this request visible to everyone?
    def all_can_view?
        return true if ['normal', 'backpage'].include?(self.prominence)
        return false
    end

    def indexed_by_search?
        if self.prominence == 'backpage' || self.prominence == 'hidden' || self.prominence == 'requester_only'
            return false
        end
        return true
    end

    # This is called from cron regularly.
    def InfoRequest.stop_new_responses_on_old_requests
        # 6 months since last change to request, only allow new incoming messages from authority domains
        InfoRequest.update_all "allow_new_responses_from = 'authority_only' where updated_at < (now() - interval '6 months') and allow_new_responses_from = 'anybody' and url_title <> 'holding_pen'"
        # 1 year since last change requests, don't allow any new incoming messages
        InfoRequest.update_all "allow_new_responses_from = 'nobody' where updated_at < (now() - interval '1 year') and allow_new_responses_from in ('anybody', 'authority_only') and url_title <> 'holding_pen'"
    end

    # Returns a random FOI request
    def InfoRequest.random
        max_id = InfoRequest.connection.select_value('select max(id) as a from info_requests').to_i
        info_request = nil
        count = 0
        while info_request.nil?
            if count > 100
                return nil
            end
            id = rand(max_id) + 1
            begin
                count += 1
                info_request = find(id, :conditions => ["prominence = 'normal'"])
            rescue ActiveRecord::RecordNotFound
            end
        end
        return info_request
    end

    def json_for_api(deep)
        ret = {
            :id => self.id,
            :url_title => self.url_title,
            :title => self.title,
            :created_at => self.created_at,
            :updated_at => self.updated_at,
            :described_state => self.described_state,
            :display_status => self.display_status,
            :awaiting_description => self.awaiting_description ,
            :prominence => self.prominence,
            :law_used => self.law_used,
            :tags => self.tag_array,

            # not sure we need to make these, mainly anti-spam, admin params public
            # allow_new_responses_from
            # handle_rejected_responses
        }

        if deep
            ret[:user] = self.user.json_for_api
            ret[:public_body] = self.public_body.json_for_api
            ret[:info_request_events] = self.info_request_events.map { |e| e.json_for_api(false) }
        end
        return ret
    end

    before_save :purge_in_cache
    def purge_in_cache
        if !Configuration::varnish_host.nil? && !self.id.nil?
            # we only do this for existing info_requests (new ones have a nil id)
            path = url_for(:controller => 'request', :action => 'show', :url_title => self.url_title, :only_path => true, :locale => :none)
            req = PurgeRequest.find_by_url(path)
            if req.nil?
                req = PurgeRequest.new(:url => path,
                                       :model => self.class.base_class.to_s,
                                       :model_id => self.id)
            end
            req.save()
        end
    end

    def for_admin_column
      self.class.content_columns.map{|c| c unless %w(title url_title).include?(c.name) }.compact.each do |column|
        yield(column.human_name, self.send(column.name), column.type.to_s, column.name)
      end
    end
end

