# -*- encoding : utf-8 -*-
# == Schema Information
# Schema version: 20131024114346
#
# Table name: info_requests
#
#  id                        :integer          not null, primary key
#  title                     :text             not null
#  user_id                   :integer
#  public_body_id            :integer          not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  described_state           :string(255)      not null
#  awaiting_description      :boolean          default(FALSE), not null
#  prominence                :string(255)      default("normal"), not null
#  url_title                 :text             not null
#  law_used                  :string(255)      default("foi"), not null
#  allow_new_responses_from  :string(255)      default("anybody"), not null
#  handle_rejected_responses :string(255)      default("bounce"), not null
#  idhash                    :string(255)      not null
#  external_user_name        :string(255)
#  external_url              :string(255)
#  attention_requested       :boolean          default(FALSE)
#  comments_allowed          :boolean          default(TRUE), not null
#  info_request_batch_id     :integer
#

require 'digest/sha1'

class InfoRequest < ActiveRecord::Base
  include AdminColumn
  include Rails.application.routes.url_helpers

  @non_admin_columns = %w(title url_title)

  strip_attributes :allow_empty => true

  validates_presence_of :title, :message => N_("Please enter a summary of your request")
  # TODO: When we no longer support Ruby 1.8, this can be done with /[[:alpha:]]/
  validates_format_of :title, :with => /[ёЁа-яА-Яa-zA-Zà-üÀ-Ü]/iu,
    :message => N_("Please write a summary with some text in it"),
    :if => Proc.new { |info_request| !info_request.title.nil? && !info_request.title.empty? }

  belongs_to :user
  validate :must_be_internal_or_external

  belongs_to :public_body, :counter_cache => true
  belongs_to :info_request_batch
  validates_presence_of :public_body_id, :unless => Proc.new { |info_request| info_request.is_batch_request_template? }

  has_many :outgoing_messages, :order => 'created_at'
  has_many :incoming_messages, :order => 'created_at'
  has_many :info_request_events, :order => 'created_at'
  has_many :user_info_request_sent_alerts
  has_many :track_things, :order => 'created_at desc'
  has_many :widget_votes, :dependent => :destroy
  has_many :comments, :order => 'created_at'
  has_many :censor_rules, :order => 'created_at desc'
  has_many :mail_server_logs, :order => 'mail_server_log_done_id'
  attr_accessor :is_batch_request_template

  has_tag_string

  scope :visible, :conditions => {:prominence => "normal"}

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

  # only check on create, so existing models with mixed case are allowed
  validate :title_formatting, :on => :create

  after_initialize :set_defaults

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

  # Subset of states accepted via the API
  def self.allowed_incoming_states
    [
      'waiting_response',
      'rejected',
      'successful',
      'partially_successful'
    ]
  end

  # Possible reasons that a request could be reported for administrator attention
  def report_reasons
    [_("Contains defamatory material"),
     _("Not a valid request"),
     _("Request for personal information"),
     _("Contains personal information"),
     _("Vexatious"),
     _("Other")]
  end

  def must_be_valid_state
    errors.add(:described_state, "is not a valid state") if
    !InfoRequest.enumerate_states.include? described_state
  end

  def is_batch_request_template?
    is_batch_request_template == true
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
        fake_slug = MySociety::Format.simplify_url_part(external_user_name, 'external_user', 32)
      end
      (public_body.url_name || "") + "_" + fake_slug
    else
      user.url_name
    end
  end

  def user_json_for_api
    is_external? ? { :name => user_name || _("Anonymous user") } : user.json_for_api
  end

  @@custom_states_loaded = false
  begin
    require 'customstates'
    include InfoRequestCustomStates
    @@custom_states_loaded = true
  rescue MissingSourceFile, NameError
  end

  OLD_AGE_IN_DAYS = 21.days

  def visible_comments
    warn %q([DEPRECATION] InfoRequest#visible_comments will be replaced with
        InfoRequest#comments.visible as of 0.23).squish
        comments.visible
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
    return MailHandler.address_from_name_and_email(self.user_name, self.incoming_email)
  end

  # Subject lines for emails about the request
  def email_subject_request(opts = {})
    html = opts.fetch(:html, true)
    _('{{law_used_full}} request - {{title}}',
      :law_used_full => self.law_used_full,
      :title => (html ? title : title.html_safe))
  end

  def email_subject_followup(opts = {})
    incoming_message = opts.fetch(:incoming_message, nil)
    html = opts.fetch(:html, true)
    if incoming_message.nil? || !incoming_message.valid_to_reply_to? || !incoming_message.subject
      'Re: ' + self.email_subject_request(:html => html)
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
  def self.find_by_incoming_email(incoming_email)
    id, hash = InfoRequest._extract_id_hash_from_email(incoming_email)
    if hash_from_id(id) == hash
      # Not using find(id) because we don't exception raised if nothing found
      find_by_id(id)
    end
  end

  # Return list of info requests which *might* be right given email address
  # e.g. For the id-hash email addresses, don't match the hash.
  def self.guess_by_incoming_email(incoming_message)
    guesses = []
    # 1. Try to guess based on the email address(es)
    incoming_message.addresses.each do |address|
      id, hash = InfoRequest._extract_id_hash_from_email(address)
      guesses.push(InfoRequest.find_by_id(id))
      guesses.push(InfoRequest.find_by_idhash(hash))
    end
    return guesses.select{|x| !x.nil?}.uniq
  end

  # Internal function used by find_by_magic_email and guess_by_incoming_email
  def self._extract_id_hash_from_email(incoming_email)
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
  # TODO: could have a date range here, so say only check last month's worth of new requests. If somebody is making
  # repeated requests, say once a quarter for time information, then might need to do that.
  # TODO: this *should* also check outgoing message joined to is an initial
  # request (rather than follow up)
  def self.find_existing(title, public_body_id, body)
    return InfoRequest.find(:first, :conditions => [ "title = ? and public_body_id = ? and outgoing_messages.body = ?", title, public_body_id, body ], :include => [ :outgoing_messages ] )
  end

  def find_existing_outgoing_message(body)
    # TODO: can add other databases here which have regexp_replace
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
      if message_id == im.message_id
        return true
      end
    end

    return false
  end

  # A new incoming email to this request
  def receive(email, raw_email_data, override_stop_new_responses = false, rejected_reason = "")
    # Is this request allowing responses?
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
        sender_email = MailHandler.get_from_address(email)
        if sender_email.nil?
          allow = false
          reason = _('Only the authority can reply to this request, but there is no "From" address to check against')
        else
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

      # If its not allowing responses, handle the message
      if !allow
        if self.handle_rejected_responses == 'bounce'
          if MailHandler.get_from_address(email).nil?
            # do nothing – can't bounce the mail as there's no
            # address to send it to
          else
            RequestMailer.stopped_responses(self, email, raw_email_data).deliver if !is_external?
          end
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

    # Take action if the message looks like spam
    spam_action = AlaveteliConfiguration.incoming_email_spam_action
    spam_threshold = AlaveteliConfiguration.incoming_email_spam_threshold
    spam_header = AlaveteliConfiguration.incoming_email_spam_header
    spam_score = email.header[spam_header].try(:value).to_f

    if spam_action && spam_header && spam_threshold && spam_score
      if spam_score > spam_threshold
        case spam_action
        when 'discard'
          # Do nothing. Silently drop spam above the threshold
          return
        when 'holding_pen'
          unless self == InfoRequest.holding_pen_request
            reason = _("Incoming message has a spam score ({{spam_score}}) " \
                       "above the configured threshold ({{spam_threshold}}).",
                       :spam_score => spam_score,
                       :spam_threshold => spam_threshold)
            request = InfoRequest.holding_pen_request
            request.receive(email, raw_email_data, false, reason)
            return
          end
        end
      end
    end

    # Otherwise log the message
    incoming_message = IncomingMessage.new

    ActiveRecord::Base.transaction do

      # To avoid a deadlock when simultaneously dealing with two
      # incoming emails that refer to the same InfoRequest, we
      # lock the row for update.  In Rails 3.2.0 and later this
      # can be done with info_request.with_lock or
      # info_request.lock!, but upgrading to that version of
      # Rails creates many other problems at the moment.  In the
      # interim, just use raw SQL to do the SELECT ... FOR UPDATE
      raw_sql = "SELECT * FROM info_requests WHERE id = #{self.id} LIMIT 1 FOR UPDATE"
      ActiveRecord::Base.connection.execute(raw_sql)

      raw_email = RawEmail.new
      incoming_message.raw_email = raw_email
      incoming_message.info_request = self
      incoming_message.save!
      raw_email.data = raw_email_data
      raw_email.save!

      self.awaiting_description = true
      params = { :incoming_message_id => incoming_message.id }
      if !rejected_reason.empty?
        params[:rejected_reason] = rejected_reason.to_str
      end
      self.log_event("response", params)
      self.save!
    end
    self.info_request_events.each { |event| event.xapian_mark_needs_index } # for the "waiting_classification" index
    RequestMailer.new_response(self, incoming_message).deliver if !is_external?
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
  def self.holding_pen_request
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
        :last_sent_at => Time.now,
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
  def self.requires_admin_states
    return ['requires_admin', 'error_message', 'attention_requested']
  end

  def requires_admin?
    ['requires_admin', 'error_message', 'attention_requested'].include?(described_state)
  end

  # Report this request for administrator attention
  def report!(reason, message, user)
    ActiveRecord::Base.transaction do
      set_described_state('attention_requested', user, "Reason: #{reason}\n\n#{message}")
      self.attention_requested = true # tells us if attention has ever been requested
      save!
    end
  end

  # change status, including for last event for later historical purposes
  # described_state should always indicate the current state of the request, as described
  # by the request owner (or, in some other cases an admin or other user)
  def set_described_state(new_state, set_by = nil, message = "")
    old_described_state = described_state
    ActiveRecord::Base.transaction do
      self.awaiting_description = false
      last_event = self.info_request_events.last
      last_event.described_state = new_state

      self.described_state = new_state
      last_event.save!
      self.save!
    end

    self.calculate_event_states

    if self.requires_admin?
      # Check there is someone to send the message "from"
      if !set_by.nil? || !self.user.nil?
        RequestMailer.requires_admin(self, set_by, message).deliver
      end
    end

    unless set_by.nil? || is_actual_owning_user?(set_by) || described_state == 'attention_requested'
      RequestMailer.old_unclassified_updated(self).deliver if !is_external?
    end
  end

  # Work out what state to display for the request on the site. In addition to values of
  # self.described_state, can take these values:
  #   waiting_classification
  #   waiting_response_overdue
  #   waiting_response_very_overdue
  # (this method adds an assessment of overdueness with respect to the current time to 'waiting_response'
  # states, and will return 'waiting_classification' instead of the described_state if the
  # awaiting_description flag is set on the request).
  def calculate_status(cached_value_ok=false)
    if cached_value_ok && @cached_calculated_status
      return @cached_calculated_status
    end
    @cached_calculated_status = @@custom_states_loaded ? self.theme_calculate_status : self.base_calculate_status
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


  # 'described_state' can be populated on any info_request_event but is only
  # ever used in the process populating calculated_state on the
  # info_request_event (if it represents a response, outgoing message, edit
  # or status update), or previous response or outgoing message events for
  # the same request.

  # Fill in any missing event states for first response before a description
  # was made. i.e. We take the last described state in between two responses
  # (inclusive of earlier), and set it as calculated value for the earlier
  # response. Also set the calculated state for any initial outgoing message,
  # follow up, edit or status_update to the described state of that event.

  # Note that the calculated state of the latest info_request_event will
  # be used in latest_status based searches and should match the described_state
  # of the info_request.
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
        event.set_calculated_state!(curr_state)

        if event.last_described_at.nil? # TODO: actually maybe this isn't needed
          event.last_described_at = Time.now
          event.save!
        end
        curr_state = nil
      elsif !curr_state.nil? && (event.event_type == 'followup_sent' || event.event_type == 'sent') && !event.described_state.nil? && (event.described_state == 'waiting_response' || event.described_state == 'internal_review')
        # Followups can set the status to waiting response / internal
        # review. Initial requests ('sent') set the status to waiting response.

        # We want to store that in calculated_state state so it gets
        # indexed.
        event.set_calculated_state!(event.described_state)

        # And we don't want to propagate it to the response itself,
        # as that might already be set to waiting_clarification / a
        # success status, which we want to know about.
        curr_state = nil
      elsif !curr_state.nil? && (['edit', 'status_update'].include? event.event_type)
        # A status update or edit event should get the same calculated state as described state
        # so that the described state is always indexed (and will be the latest_status
        # for the request immediately after it has been described, regardless of what
        # other request events precede it). This means that request should be correctly included
        # in status searches for that status. These events allow the described state to propagate in
        # case there is a preceding response that the described state should be applied to.
        event.set_calculated_state!(event.described_state)
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
          # TODO: this needs to cope with followup_resent, which it doesn't.
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
    Holiday.due_date_from(self.date_initial_request_last_sent_at, AlaveteliConfiguration::reply_late_after_days, AlaveteliConfiguration::working_or_calendar_days)
  end
  # This is a long stop - even with UK public interest test extensions, 40
  # days is a very long time.
  def date_very_overdue_after
    if self.public_body.is_school?
      # schools have 60 working days maximum (even over a long holiday)
      Holiday.due_date_from(self.date_initial_request_last_sent_at, AlaveteliConfiguration::special_reply_very_late_after_days, AlaveteliConfiguration::working_or_calendar_days)
    else
      # public interest test ICO guidance gives 40 working maximum
      Holiday.due_date_from(self.date_initial_request_last_sent_at, AlaveteliConfiguration::reply_very_late_after_days, AlaveteliConfiguration::working_or_calendar_days)
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
    return MailHandler.address_from_name_and_email(
      _("{{law_used}} requests at {{public_body}}",
        :law_used => self.law_used_short,
        :public_body => self.public_body.short_or_long_name),
        self.recipient_email)
  end

  # History of some things that have happened
  def log_event(type, params)
    self.info_request_events.create!(:event_type => type, :params => params)
  end

  def public_response_events
    condition = <<-SQL
        info_request_events.event_type = ?
        AND incoming_messages.prominence = ?
    SQL

    info_request_events.
      joins(:incoming_message).
      where(condition, 'response', 'normal')
  end

  # The last public response is the default one people might want to reply to
  def get_last_public_response_event_id
    get_last_public_response_event.id if get_last_public_response_event
  end

  def get_last_public_response_event
    public_response_events.last
  end

  def get_last_public_response
    get_last_public_response_event.incoming_message if get_last_public_response_event
  end

  def public_outgoing_events
    info_request_events.select{|e| e.outgoing? && e.outgoing_message.all_can_view? }
  end

  # The last public outgoing message
  def get_last_public_outgoing_event
    public_outgoing_events.last
  end

  # Text from the the initial request, for use in summary display
  def initial_request_text
    return '' if outgoing_messages.empty?
    body_opts = { :censor_rules => applicable_censor_rules }
    first_message = outgoing_messages.first
    first_message.all_can_view? ? first_message.get_text_for_indexing(true, body_opts) : ''
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

  def last_update_hash
    Digest::SHA1.hexdigest(info_request_events.last.created_at.to_i.to_s + updated_at.to_i.to_s)
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
  def self.get_status_description(status)
    descriptions = {
      'waiting_classification'        => _("Awaiting classification."),
      'waiting_response'              => _("Awaiting response."),
      'waiting_response_overdue'      => _("Delayed."),
      'waiting_response_very_overdue' => _("Long overdue."),
      'not_held'                      => _("Information not held."),
      'rejected'                      => _("Refused."),
      'partially_successful'          => _("Partially successful."),
      'successful'                    => _("Successful."),
      'waiting_clarification'         => _("Waiting clarification."),
      'gone_postal'                   => _("Handled by post."),
      'internal_review'               => _("Awaiting internal review."),
      'error_message'                 => _("Delivery error"),
      'requires_admin'                => _("Unusual response."),
      'attention_requested'           => _("Reported for administrator attention."),
      'user_withdrawn'                => _("Withdrawn by the requester."),
      'vexatious'                     => _("Considered by administrators as vexatious and hidden from site."),
      'not_foi'                       => _("Considered by administrators as not an FOI request and hidden from site."),
    }
    if descriptions[status]
      descriptions[status]
    elsif respond_to?(:theme_display_status)
      theme_display_status(status)
    else
      raise _("unknown status ") + status
    end
  end

  def display_status(cached_value_ok=false)
    InfoRequest.get_status_description(self.calculate_status(cached_value_ok))
  end

  # Completely delete this request and all objects depending on it
  def fully_destroy
    track_things.each do |track_thing|
      track_thing.track_things_sent_emails.each { |a| a.destroy }
      track_thing.destroy
    end
    user_info_request_sent_alerts.each { |a| a.destroy }
    info_request_events.each do |info_request_event|
      info_request_event.track_things_sent_emails.each { |a| a.destroy }
      info_request_event.destroy
    end
    mail_server_logs.each do |mail_server_log|
      mail_server_log.destroy
    end
    outgoing_messages.each { |a| a.destroy }
    incoming_messages.each { |a| a.destroy }
    comments.each { |comment| comment.destroy }
    censor_rules.each{ |censor_rule| censor_rule.destroy }

    destroy
  end

  # Called by incoming_email - and used to be called to generate separate
  # envelope from address until we abandoned it.
  def magic_email(prefix_part)
    raise "id required to create a magic email" if not self.id
    return InfoRequest.magic_email_for_id(prefix_part, self.id)
  end

  def self.magic_email_for_id(prefix_part, id)
    magic_email = AlaveteliConfiguration::incoming_email_prefix
    magic_email += prefix_part + id.to_s
    magic_email += "-" + InfoRequest.hash_from_id(id)
    magic_email += "@" + AlaveteliConfiguration::incoming_email_domain
    return magic_email
  end

  before_validation :compute_idhash

  def compute_idhash
    self.idhash = InfoRequest.hash_from_id(self.id)
  end

  def self.create_from_attributes(info_request_atts, outgoing_message_atts, user=nil)
    info_request = new(info_request_atts)
    default_message_params = {
      :status => 'ready',
      :message_type => 'initial_request',
      :what_doing => 'normal_sort'
    }
    outgoing_message = OutgoingMessage.new(outgoing_message_atts.merge(default_message_params))
    info_request.outgoing_messages << outgoing_message
    outgoing_message.info_request = info_request
    info_request.user = user
    info_request
  end

  def self.hash_from_id(id)
    return Digest::SHA1.hexdigest(id.to_s + AlaveteliConfiguration::incoming_email_secret)[0,8]
  end

  # Used to find when event last changed
  def self.last_event_time_clause(event_type=nil, join_table=nil, join_clause=nil)
    event_type_clause = ''
    event_type_clause = " AND info_request_events.event_type = '#{event_type}'" if event_type
    tables = ['info_request_events']
    tables << join_table if join_table
    join_clause = "AND #{join_clause}" if join_clause
    "(SELECT info_request_events.created_at
          FROM #{tables.join(', ')}
          WHERE info_request_events.info_request_id = info_requests.id
          #{event_type_clause}
          #{join_clause}
          ORDER BY created_at desc
          LIMIT 1)"
  end

  def self.last_public_response_clause
    join_clause = "incoming_messages.id = info_request_events.incoming_message_id
                       AND incoming_messages.prominence = 'normal'"
    last_event_time_clause('response', 'incoming_messages', join_clause)
  end

  def self.old_unclassified_params(extra_params, include_last_response_time=false)
    last_response_created_at = last_public_response_clause
    age = extra_params[:age_in_days] ? extra_params[:age_in_days].days : OLD_AGE_IN_DAYS
    params = { :conditions => ["awaiting_description = ?
                                    AND #{last_response_created_at} < ?
                                    AND url_title != 'holding_pen'
                                    AND user_id IS NOT NULL",
                                      true, Time.now - age] }
    if include_last_response_time
      params[:select] = "*, #{last_response_created_at} AS last_response_time"
      params[:order] = 'last_response_time'
    end
    return params
  end

  def self.count_old_unclassified(extra_params={})
    params = old_unclassified_params(extra_params)
    add_conditions_from_extra_params(params, extra_params)
    count(:all, params)
  end

  def self.get_random_old_unclassified(limit, extra_params)
    params = old_unclassified_params({})
    add_conditions_from_extra_params(params, extra_params)
    params[:limit] = limit
    params[:order] = "random()"
    find(:all, params)
  end

  def self.find_old_unclassified(extra_params={})
    params = old_unclassified_params(extra_params, include_last_response_time=true)
    [:limit, :include, :offset].each do |extra|
      params[extra] = extra_params[extra] if extra_params[extra]
    end
    if extra_params[:order]
      params[:order] = extra_params[:order]
      params.delete(:select)
    end
    add_conditions_from_extra_params(params, extra_params)
    find(:all, params)
  end

  def self.download_zip_dir
    File.join(Rails.root, "cache", "zips", "#{Rails.env}")
  end

  def foi_fragment_cache_directories
    # return stub path so admin can expire it
    directories = []
    path = File.join("request", request_dirs)
    foi_cache_path = File.expand_path(File.join(Rails.root, 'cache', 'views'))
    directories << File.join(foi_cache_path, path)
    I18n.available_locales.each do |locale|
      directories << File.join(foi_cache_path, locale.to_s, path)
    end

    directories
  end

  def request_dirs
    first_three_digits = id.to_s[0..2]
    File.join(first_three_digits.to_s, id.to_s)
  end

  def download_zip_dir
    File.join(InfoRequest.download_zip_dir, "download", request_dirs)
  end

  def make_zip_cache_path(user)
    cache_file_dir = File.join(InfoRequest.download_zip_dir,
                               "download",
                               request_dirs,
                               last_update_hash)
    cache_file_suffix = if all_can_view_all_correspondence?
                          ""
                        elsif Ability.can_view_with_prominence?('hidden', self, user)
                          "_hidden"
                        elsif Ability.can_view_with_prominence?('requester_only', self, user)
                          "_requester_only"
                        else
                          ""
                        end
    File.join(cache_file_dir, "#{url_title}#{cache_file_suffix}.zip")
  end

  def is_old_unclassified?
    !is_external? && awaiting_description && url_title != 'holding_pen' && get_last_public_response_event &&
      Time.now > get_last_public_response_event.created_at + OLD_AGE_IN_DAYS
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

      next if ! incoming_message.all_can_view?

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
    applicable_rules = [self.censor_rules, CensorRule.global.all]
    unless is_batch_request_template?
      applicable_rules << self.public_body.censor_rules
    end
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

  # Masks we apply to text associated with this request convert email addresses
  # we know about into textual descriptions of them
  def masks
    masks = [{ :to_replace => incoming_email,
               :replacement =>  _('[FOI #{{request}} email]',
                                  :request => id.to_s) },
                                  { :to_replace => AlaveteliConfiguration::contact_email,
                                    :replacement => _("[{{site_name}} contact email]",
                                                      :site_name => AlaveteliConfiguration::site_name)} ]
    if public_body.is_followupable?
      masks << { :to_replace => public_body.request_email,
                 :replacement => _("[{{public_body}} request email]",
                                   :public_body => public_body.short_or_long_name) }
    end
  end

  def is_owning_user?(user)
    !user.nil? && (user.id == user_id || user.owns_every_request?)
  end
  def is_actual_owning_user?(user)
    !user.nil? && user.id == user_id
  end

  def user_can_view?(user)
    Ability.can_view_with_prominence?(self.prominence, self, user)
  end

  # Is this request visible to everyone?
  def all_can_view?
    return true if ['normal', 'backpage'].include?(self.prominence)
    return false
  end

  def all_can_view_all_correspondence?
    all_can_view? &&
      incoming_messages.all?{ |message| message.all_can_view? } &&
      outgoing_messages.all?{ |message| message.all_can_view? }
  end

  def indexed_by_search?
    if self.prominence == 'backpage' || self.prominence == 'hidden' || self.prominence == 'requester_only'
      return false
    end
    return true
  end

  # This is called from cron regularly.
  def self.stop_new_responses_on_old_requests
    # 6 months since last change to request, only allow new incoming messages from authority domains
    InfoRequest.update_all "allow_new_responses_from = 'authority_only' where updated_at < (now() - interval '6 months') and allow_new_responses_from = 'anybody' and url_title <> 'holding_pen'"
    # 1 year since last change requests, don't allow any new incoming messages
    InfoRequest.update_all "allow_new_responses_from = 'nobody' where updated_at < (now() - interval '1 year') and allow_new_responses_from in ('anybody', 'authority_only') and url_title <> 'holding_pen'"
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
      if self.user
        ret[:user] = self.user.json_for_api
      else
        ret[:user_name] = self.user_name
      end
      ret[:public_body] = self.public_body.json_for_api
      ret[:info_request_events] = self.info_request_events.map { |e| e.json_for_api(false) }
    end
    return ret
  end

  before_save :purge_in_cache
  def purge_in_cache
    if !AlaveteliConfiguration::varnish_host.blank? && !self.id.nil?
      # we only do this for existing info_requests (new ones have a nil id)
      path = url_for(:controller => 'request', :action => 'show', :url_title => self.url_title, :only_path => true, :locale => :none)
      req = PurgeRequest.find_by_url(path)
      if req.nil?
        req = PurgeRequest.new(:url => path,
                               :model => self.class.base_class.to_s,
                               :model_id => self.id)
      end
      req.save
    end
  end

  after_save :update_counter_cache
  after_destroy :update_counter_cache
  # This method updates the count columns of the PublicBody that
  # store the number of "not held", "to some extent successful" and
  # "both visible and classified" requests when saving or destroying
  # an InfoRequest associated with the body:
  def update_counter_cache
    PublicBody.skip_callback(:save, :after, :purge_in_cache)
    basic_params = {
      :public_body_id => self.public_body_id,
      :awaiting_description => false,
      :prominence => 'normal'
    }
    [['info_requests_not_held_count', {:described_state => 'not_held'}],
     ['info_requests_successful_count', {:described_state => ['successful', 'partially_successful']}],
     ['info_requests_visible_classified_count', {}]].each do |column, extra_params|
       params = basic_params.clone.update extra_params
       self.public_body.send "#{column}=", InfoRequest.where(params).count
     end
     self.public_body.without_revision do
       public_body.no_xapian_reindex = true
       public_body.save
     end
     PublicBody.set_callback(:save, :after, :purge_in_cache)
  end

  # Get requests that have similar important terms
  def similar_requests(limit=10)
    xapian_similar = nil
    xapian_similar_more = false
    begin
      xapian_similar = ActsAsXapian::Similar.new([InfoRequestEvent],
                                                 info_request_events,
                                                 :limit => limit,
                                                 :collapse_by_prefix => 'request_collapse')
      xapian_similar_more = (xapian_similar.matches_estimated > limit)
    rescue
    end
    return [xapian_similar, xapian_similar_more]
  end

  def self.request_list(filters, page, per_page, max_results)
    xapian_object = ActsAsXapian::Search.new([InfoRequestEvent],
                                             InfoRequestEvent.make_query_from_params(filters),
                                             :offset => (page - 1) * per_page,
                                             :limit => 25,
                                             :sort_by_prefix => 'created_at',
                                             :sort_by_ascending => true,
                                             :collapse_by_prefix => 'request_collapse'
                                            )
    list_results = xapian_object.results.map { |r| r[:model] }
    matches_estimated = xapian_object.matches_estimated
    show_no_more_than = [matches_estimated, max_results].min
    return { :results => list_results,
             :matches_estimated => matches_estimated,
             :show_no_more_than => show_no_more_than }
  end

  def self.recent_requests
    request_events = []
    request_events_all_successful = false
    # Get some successful requests
    begin
      query = 'variety:response (status:successful OR status:partially_successful)'
      sortby = "newest"
      max_count = 5

      xapian_object = ActsAsXapian::Search.new([InfoRequestEvent],
                                               query,
                                               :offset => 0,
                                               :limit => 5,
                                               :sort_by_prefix => 'created_at',
                                               :sort_by_ascending => true,
                                               :collapse_by_prefix => 'request_title_collapse'
                                              )
      xapian_object.results
      request_events = xapian_object.results.map { |r| r[:model] }

      # If there are not yet enough successful requests, fill out the list with
      # other requests
      if request_events.count < max_count
        query = 'variety:sent'
        xapian_object = ActsAsXapian::Search.new([InfoRequestEvent],
                                                 query,
                                                 :offset => 0,
                                                 :limit => max_count-request_events.count,
                                                 :sort_by_prefix => 'created_at',
                                                 :sort_by_ascending => true,
                                                 :collapse_by_prefix => 'request_title_collapse'
                                                )
        xapian_object.results
        more_events = xapian_object.results.map { |r| r[:model] }
        request_events += more_events
        # Overall we still want the list sorted with the newest first
        request_events.sort!{|e1,e2| e2.created_at <=> e1.created_at}
      else
        request_events_all_successful = true
      end
    rescue
      request_events = []
    end

    return [request_events, request_events_all_successful]
  end

  def self.find_in_state(state)
    select("*, #{ last_event_time_clause } as last_event_time").
    where(:described_state => state).
      order('last_event_time')
  end

  def move_to_public_body(destination_public_body, opts = {})
    old_body = public_body
    editor = opts.fetch(:editor)

    attrs = { :public_body => destination_public_body }

    if destination_public_body
      attrs.merge!({
        :law_used => destination_public_body.law_only_short.downcase
      })
    end

    if update_attributes(attrs)
      log_event('move_request',
                :editor => editor,
                :public_body_url_name => public_body.url_name,
                :old_public_body_url_name => old_body.url_name)

      reindex_request_events

      public_body
    end
  end

  # The DateTime of the last InfoRequestEvent belonging to the InfoRequest
  # Only available if the last_event_time attribute has been set. This is
  # currentlt only set through .find_in_state
  #
  # Returns a DateTime
  def last_event_time
    attributes['last_event_time'].try(:to_datetime)
  end

  private

  def set_defaults
    begin
      if self.described_state.nil?
        self.described_state = 'waiting_response'
      end
    rescue ActiveModel::MissingAttributeError
      # this should only happen on Model.exists? call. It can be safely ignored.
      # See http://www.tatvartha.com/2011/03/activerecordmissingattributeerror-missing-attribute-a-bug-or-a-features/
    end

    # FOI or EIR?
    if new_record? && public_body && public_body.eir_only?
      self.law_used = 'eir'
    end
  end

  def title_formatting
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

  def self.add_conditions_from_extra_params(params, extra_params)
    if extra_params[:conditions]
      condition_string = extra_params[:conditions].shift
      params[:conditions][0] += " AND #{condition_string}"
      params[:conditions] += extra_params[:conditions]
    end
  end
end

