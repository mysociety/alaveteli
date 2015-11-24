# -*- encoding : utf-8 -*-
# == Schema Information
# Schema version: 20151104131702
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
#  last_public_response_at   :datetime
#

require 'digest/sha1'
require 'fileutils'

class InfoRequest < ActiveRecord::Base
  include AdminColumn
  include Rails.application.routes.url_helpers

  # Two sorts of laws for requests, FOI or EIR
  LAW_USED_READABLE_DATA =
    { :foi => { :short => _('FOI'),
                :full => _('Freedom of Information'),
                :with_a => _('A Freedom of Information request'),
                :act => _('Freedom of Information Act') },
      :eir => { :short => _('EIR'),
                :full => _('Environmental Information Regulations'),
                :with_a => _('An Environmental Information request'),
                :act => _('Environmental Information Regulations') }
    }

  @non_admin_columns = %w(title url_title)

  strip_attributes :allow_empty => true

  validates_presence_of :title, :message => N_("Please enter a summary of your request")
  validates_format_of :title, :with => /[[:alpha:]]/,
    :message => N_("Please write a summary with some text in it"),
    :unless => Proc.new { |info_request| info_request.title.blank? }
  validates :title, :length => {
    :maximum => 200,
    :message => _('Please keep the summary short, like in the subject of an ' \
                  'email. You can use a phrase, rather than a full sentence.')
  }

  belongs_to :user
  validate :must_be_internal_or_external

  belongs_to :public_body, :counter_cache => true
  belongs_to :info_request_batch
  validates_presence_of :public_body_id, :unless => Proc.new { |info_request| info_request.is_batch_request_template? }

  has_many :info_request_events, :order => 'created_at', :dependent => :destroy
  has_many :outgoing_messages, :order => 'created_at', :dependent => :destroy
  has_many :incoming_messages, :order => 'created_at', :dependent => :destroy
  has_many :user_info_request_sent_alerts, :dependent => :destroy
  has_many :track_things, :order => 'created_at desc', :dependent => :destroy
  has_many :widget_votes, :dependent => :destroy
  has_many :comments, :order => 'created_at', :dependent => :destroy
  has_many :censor_rules, :order => 'created_at desc', :dependent => :destroy
  has_many :mail_server_logs, :order => 'mail_server_log_done_id', :dependent => :destroy
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
  after_save :update_counter_cache
  after_destroy :update_counter_cache
  after_update :reindex_some_request_events
  before_destroy :expire
  before_save :purge_in_cache
  # make sure the url_title is unique but don't update
  # existing requests unless the title is being changed
  before_save :update_url_title,
    :if => Proc.new { |request| request.title_changed? }
  before_validation :compute_idhash

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
    unless InfoRequest.enumerate_states.include?(described_state)
      errors.add(:described_state, "is not a valid state")
    end
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
    if user_id
      errors.add(:external_user_name, "must be null for an internal request") unless external_user_name.nil?
      errors.add(:external_url, "must be null for an internal request") unless external_url.nil?
    end
  end

  def is_external?
    external_url.nil? ? false : true
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

  # If the URL name has changed, then all request: queries will break unless
  # we update index for every event. Also reindex if prominence changes.
  def reindex_some_request_events
    if changes.include?('url_title') || changes.include?('prominence') || changes.include?('user_id')
      reindex_request_events
    end
  end

  def reindex_request_events
    for info_request_event in info_request_events
      info_request_event.xapian_mark_needs_index
    end
  end

  # Force reindex when tag string changes
  alias_method :orig_tag_string=, :tag_string=
  def tag_string=(tag_string)
    ret = self.orig_tag_string=(tag_string)
    reindex_request_events
    ret
  end

  def expire
    # Clear out cached entries, by removing files from disk (the built in
    # Rails fragment cache made doing this and other things too hard)
    foi_fragment_cache_directories.each{ |dir| FileUtils.rm_rf(dir) }

    # Remove any download zips
    FileUtils.rm_rf(download_zip_dir)

    # Remove the database caches of body / attachment text (the attachment text
    # one is after privacy rules are applied)
    clear_in_database_caches!

    # also force a search reindexing (so changed text reflected in search)
    reindex_request_events
    # and remove from varnish
    purge_in_cache
  end

  # Removes anything cached about the object in the database, and saves
  def clear_in_database_caches!
    for incoming_message in incoming_messages
      incoming_message.clear_in_database_caches!
    end
  end

  # When name is changed, also change the url name
  def title=(title)
    write_attribute(:title, title)
    update_url_title
  end

  # Public: url_title attribute reader
  #
  # opts - Hash of options (default: {})
  #        :collapse - Set true to strip the numeric section. Use this to group
  #                    lots of similar requests by url_title.
  #
  # Returns a String
  def url_title(opts = {})
    _url_title = super()
    return _url_title.gsub(/[_0-9]+$/, "") if opts[:collapse]
    _url_title
  end

  def update_url_title
    return unless title
    url_title = MySociety::Format.simplify_url_part(title, 'request', 32)
    # For request with same title as others, add on arbitary numeric identifier
    unique_url_title = url_title
    suffix_num = 2 # as there's already one without numeric suffix
    while InfoRequest.
            find_by_url_title(unique_url_title,
                              :conditions => id.nil? ? nil : ["id <> ?", id])
      unique_url_title = "#{url_title}_#{suffix_num}"
      suffix_num = suffix_num + 1
    end
    write_attribute(:url_title, unique_url_title)
  end

  def update_last_public_response_at
    last_public_event = get_last_public_response_event
    if last_public_event
      self.last_public_response_at = last_public_event.created_at
    else
      self.last_public_response_at = nil
    end
    save
  end

  # Remove spaces from ends (for when used in emails etc.)
  # Needed for legacy reasons, even though we call strip_attributes now
  def title
    title = read_attribute(:title)
    if title
      title.strip!
    end
    title
  end

  # Email which public body should use to respond to request. This is in
  # the format PREFIXrequest-ID-HASH@DOMAIN. Here ID is the id of the
  # FOI request, and HASH is a signature for that id.
  def incoming_email
    magic_email("request-")
  end

  def incoming_name_and_email
    MailHandler.address_from_name_and_email(user_name, incoming_email)
  end

  # Subject lines for emails about the request
  def email_subject_request(opts = {})
    html = opts.fetch(:html, true)
    _('{{law_used_full}} request - {{title}}',
      :law_used_full => law_used_human(:full),
      :title => (html ? title : title.html_safe))
  end

  def email_subject_followup(opts = {})
    incoming_message = opts.fetch(:incoming_message, nil)
    html = opts.fetch(:html, true)
    if incoming_message.nil? || !incoming_message.valid_to_reply_to? || !incoming_message.subject
      'Re: ' + email_subject_request(:html => html)
    else
      if incoming_message.subject.match(/^Re:/i)
        incoming_message.subject
      else
        'Re: ' + incoming_message.subject
      end
    end
  end

  def law_used_full
    warn %q([DEPRECATION] law_used_full will be replaced with
      InfoRequest#law_used_human(:full) as of 0.24).squish
    law_used_human(:full)
  end

  def law_used_short
    warn %q([DEPRECATION] law_used_short will be replaced with
      InfoRequest#law_used_human(:short) as of 0.24).squish
    law_used_human(:short)
  end

  def law_used_act
    warn %q([DEPRECATION] law_used_act will will be replaced with
      InfoRequest#law_used_human(:act) as of 0.24).squish
    law_used_human(:act)
  end

  def law_used_with_a
    warn %q([DEPRECATION] law_used_with_a will be removed in Alaveteli
           release 0.24).squish
    law_used_human(:with_a)
  end

  def law_used_human(key = :full)
    begin
      applicable_law.fetch(key)
    rescue KeyError
      raise "Unknown key '#{key}' for '#{law_used}'"
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
    guesses.compact.uniq
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

    if hash
      # Convert l to 1, and o to 0. FOI officers quite often retype the
      # email address and make this kind of error.
      hash.gsub!(/l/, "1")
      hash.gsub!(/o/, "0")
    end

    [id, hash]
  end

  # When constructing a new request, use this to check user hasn't double submitted.
  # TODO: could have a date range here, so say only check last month's worth of new requests. If somebody is making
  # repeated requests, say once a quarter for time information, then might need to do that.
  # TODO: this *should* also check outgoing message joined to is an initial
  # request (rather than follow up)
  def self.find_existing(title, public_body_id, body)
    InfoRequest.find(:first, :conditions => [ "title = ? and public_body_id = ? and outgoing_messages.body = ?", title, public_body_id, body ], :include => [ :outgoing_messages ] )
  end

  def find_existing_outgoing_message(body)
    # TODO: can add other databases here which have regexp_replace
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      # Exclude spaces from the body comparison using regexp_replace
      outgoing_messages.find(:first, :conditions => [ "regexp_replace(outgoing_messages.body, '[[:space:]]', '', 'g') = regexp_replace(?, '[[:space:]]', '', 'g')", body ])
    else
      # For other databases (e.g. SQLite) not the end of the world being space-sensitive for this check
      outgoing_messages.find(:first, :conditions => [ "outgoing_messages.body = ?", body ])
    end
  end

  # Has this email already been received here? Based just on message id.
  def already_received?(email, raw_email_data)
    message_id = email.message_id
    if message_id.nil?
      raise "No message id for this message"
    end

    for im in incoming_messages
      if message_id == im.message_id
        return true
      end
    end

    false
  end

  # A new incoming email to this request
  def receive(email, raw_email_data, override_stop_new_responses = false, rejected_reason = nil)
    # Is this request allowing responses?
    accepted =
      if override_stop_new_responses
        true
      else
        accept_incoming?(email, raw_email_data)
      end

    if accepted
      incoming_message =
        create_response!(email, raw_email_data, rejected_reason)

      # Notify the user that a new response has been received, unless the
      # request is external
      unless is_external?
        RequestMailer.new_response(self, incoming_message).deliver
      end
    end
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

      log_event("comment", { :comment_id => comment.id })
      save!
    end
    comment
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
    ir
  end

  # states which require administrator action (hence email administrators
  # when they are entered, and offer state change dialog to them)
  def self.requires_admin_states
    %w(requires_admin error_message attention_requested)
  end

  def requires_admin?
    self.class.requires_admin_states.include?(described_state)
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
      last_event = info_request_events.last
      last_event.described_state = new_state

      self.described_state = new_state
      last_event.save!
      save!
    end

    calculate_event_states

    if requires_admin?
      # Check there is someone to send the message "from"
      if set_by && user
        RequestMailer.requires_admin(self, set_by, message).deliver
      end
    end

    unless set_by.nil? || is_actual_owning_user?(set_by) || described_state == 'attention_requested'
      RequestMailer.old_unclassified_updated(self).deliver unless is_external?
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
    @cached_calculated_status = @@custom_states_loaded ? theme_calculate_status : base_calculate_status
  end

  def base_calculate_status
    return 'waiting_classification' if awaiting_description
    return described_state unless described_state == "waiting_response"
    # Compare by date, so only overdue on next day, not if 1 second late
    return 'waiting_response_very_overdue' if
    Time.now.strftime("%Y-%m-%d") > date_very_overdue_after.strftime("%Y-%m-%d")
    return 'waiting_response_overdue' if
    Time.now.strftime("%Y-%m-%d") > date_response_required_by.strftime("%Y-%m-%d")
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
    for event in info_request_events.reverse
      event.xapian_mark_needs_index  # we need to reindex all events in order to update their latest_* terms
      if curr_state.nil?
        if event.described_state
          curr_state = event.described_state
        end
      end

      if curr_state && event.event_type == 'response'
        event.set_calculated_state!(curr_state)

        if event.last_described_at.nil? # TODO: actually maybe this isn't needed
          event.last_described_at = Time.now
          event.save!
        end
        curr_state = nil
      elsif curr_state && (event.event_type == 'followup_sent' || event.event_type == 'sent') && event.described_state && (event.described_state == 'waiting_response' || event.described_state == 'internal_review')
        # Followups can set the status to waiting response / internal
        # review. Initial requests ('sent') set the status to waiting response.

        # We want to store that in calculated_state state so it gets
        # indexed.
        event.set_calculated_state!(event.described_state)

        # And we don't want to propagate it to the response itself,
        # as that might already be set to waiting_clarification / a
        # success status, which we want to know about.
        curr_state = nil
      elsif curr_state && (['edit', 'status_update'].include? event.event_type)
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
    for event in info_request_events
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
      raise "internal error, last_event_forming_initial_request gets nil for request " + id.to_s + " outgoing messages count " + outgoing_messages.size.to_s + " all events: " + info_request_events.to_yaml
    end
    last_sent
  end

  # The last time that the initial request was sent/resent
  def date_initial_request_last_sent_at
    last_sent = last_event_forming_initial_request
    last_sent.outgoing_message.last_sent_at
  end

  # How do we cope with case where extra info was required from the requester
  # by the public body in order to fulfill the request, as per sections 1(3)
  # and 10(6b) ? For clarifications this is covered by
  # last_event_forming_initial_request. There may be more obscure
  # things, e.g. fees, not properly covered.
  def date_response_required_by
    Holiday.due_date_from(date_initial_request_last_sent_at, AlaveteliConfiguration::reply_late_after_days, AlaveteliConfiguration::working_or_calendar_days)
  end

  # This is a long stop - even with UK public interest test extensions, 40
  # days is a very long time.
  def date_very_overdue_after
    if public_body.is_school?
      # schools have 60 working days maximum (even over a long holiday)
      Holiday.due_date_from(date_initial_request_last_sent_at, AlaveteliConfiguration::special_reply_very_late_after_days, AlaveteliConfiguration::working_or_calendar_days)
    else
      # public interest test ICO guidance gives 40 working maximum
      Holiday.due_date_from(date_initial_request_last_sent_at, AlaveteliConfiguration::reply_very_late_after_days, AlaveteliConfiguration::working_or_calendar_days)
    end
  end

  # Where the initial request is sent to
  def recipient_email
    public_body.request_email
  end

  def recipient_email_valid_for_followup?
    public_body.is_followupable?
  end

  def recipient_name_and_email
    MailHandler.address_from_name_and_email(
      _("{{law_used}} requests at {{public_body}}",
        :law_used => law_used_human(:short),
        :public_body => public_body.short_or_long_name),
        recipient_email)
  end

  # History of some things that have happened
  def log_event(type, params)
    info_request_events.create!(:event_type => type, :params => params)
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
    events = info_request_events
    events.each_index do |i|
      revi = events.size - 1 - i
      m = events[revi]
      return revi if m.described_state
    end
    nil
  end

  def last_event_id_needing_description
    last_event = events_needing_description[-1]
    last_event.nil? ? 0 : last_event.id
  end

  # Returns all the events which the user hasn't described yet - an empty array if all described.
  def events_needing_description
    events = info_request_events
    i = index_of_last_described_event
    if i.nil?
      events
    else
      events[i + 1, events.size]
    end
  end

  # Returns last event
  def get_last_event
    events = info_request_events
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
    for e in info_request_events
      if ((info_request_event.is_sent_sort? && e.is_sent_sort?) || (info_request_event.is_followup_sort? && e.is_followup_sort?)) && e.outgoing_message_id == info_request_event.outgoing_message_id
        if e.id == info_request_event.id
          break
        end
        last_email = e.params[:email]
      end
    end
    last_email
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
    InfoRequest.get_status_description(calculate_status(cached_value_ok))
  end

  # Completely delete this request and all objects depending on it
  def fully_destroy
    warn %q([DEPRECATION] InfoRequest#fully_destroy will be replaced with
      InfoRequest#destroy as of 0.24).squish
    destroy
  end

  # Called by incoming_email - and used to be called to generate separate
  # envelope from address until we abandoned it.
  def magic_email(prefix_part)
    raise "id required to create a magic email" if not id
    InfoRequest.magic_email_for_id(prefix_part, id)
  end

  def self.magic_email_for_id(prefix_part, id)
    magic_email = AlaveteliConfiguration::incoming_email_prefix
    magic_email += prefix_part + id.to_s
    magic_email += "-" + InfoRequest.hash_from_id(id)
    magic_email += "@" + AlaveteliConfiguration::incoming_email_domain
    magic_email
  end

  def compute_idhash
    self.idhash = InfoRequest.hash_from_id(id)
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
    Digest::SHA1.hexdigest(id.to_s + AlaveteliConfiguration::incoming_email_secret)[0,8]
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
    # TODO: Deprecate this method
    join_clause = "incoming_messages.id = info_request_events.incoming_message_id
                       AND incoming_messages.prominence = 'normal'"
    last_event_time_clause('response', 'incoming_messages', join_clause)
  end

  def self.old_unclassified_params(extra_params, include_last_response_time=false)
    age = extra_params[:age_in_days] ? extra_params[:age_in_days].days : OLD_AGE_IN_DAYS
    params = { :conditions => ["awaiting_description = ?
                                    AND last_public_response_at < ?
                                    AND url_title != 'holding_pen'
                                    AND user_id IS NOT NULL",
                                      true, Time.zone.now - age] }
    if include_last_response_time
      params[:order] = 'last_public_response_at'
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
    for incoming_message in incoming_messages.reverse
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

    if !done.include?(public_body.request_email.downcase)
      ret = ret + [[public_body.name, public_body.request_email, nil]]
    end
    done[public_body.request_email.downcase] = 1

    ret.reverse
  end

  # Get the list of censor rules that apply to this request
  def applicable_censor_rules
    applicable_rules = [censor_rules, CensorRule.global.all]
    unless is_batch_request_template?
      applicable_rules << public_body.censor_rules
    end
    if user && !user.censor_rules.empty?
      applicable_rules << user.censor_rules
    end
    applicable_rules.flatten
  end

  # Call groups of censor rules
  def apply_censor_rules_to_text!(text)
    applicable_censor_rules.each do |censor_rule|
      censor_rule.apply_to_text!(text)
    end
    text
  end

  def apply_censor_rules_to_binary!(binary)
    applicable_censor_rules.each do |censor_rule|
      censor_rule.apply_to_binary!(binary)
    end
    binary
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
    return false unless user
    user.id == user_id || user.owns_every_request?
  end

  def is_actual_owning_user?(user)
    return false unless user
    user.id == user_id
  end

  def user_can_view?(user)
    Ability.can_view_with_prominence?(prominence, self, user)
  end

  # Is this request visible to everyone?
  def all_can_view?
    %w(normal backpage).include?(prominence)
  end

  def all_can_view_all_correspondence?
    all_can_view? &&
      incoming_messages.all?{ |message| message.all_can_view? } &&
      outgoing_messages.all?{ |message| message.all_can_view? }
  end

  def indexed_by_search?
    if prominence == 'backpage' || prominence == 'hidden' || prominence == 'requester_only'
      return false
    end
    true
  end

  # This is called from cron regularly.
  def self.stop_new_responses_on_old_requests
    old = AlaveteliConfiguration.restrict_new_responses_on_old_requests_after_months
    very_old = old * 2
    # 'old' months since last change to request, only allow new incoming
    # messages from authority domains
    InfoRequest.update_all <<-EOF.strip_heredoc.delete("\n")
    allow_new_responses_from = 'authority_only'
    WHERE updated_at < (now() - interval '#{ old } months')
    AND allow_new_responses_from = 'anybody'
    AND url_title <> 'holding_pen'
    EOF

    # 'very_old' months since last change requests, don't allow any new
    # incoming messages
    InfoRequest.update_all <<-EOF.strip_heredoc.delete("\n")
    allow_new_responses_from = 'nobody'
    WHERE updated_at < (now() - interval '#{ very_old } months')
    AND allow_new_responses_from IN ('anybody', 'authority_only')
    AND url_title <> 'holding_pen'
    EOF
  end

  def json_for_api(deep)
    ret = {
      :id => id,
      :url_title => url_title,
      :title => title,
      :created_at => created_at,
      :updated_at => updated_at,
      :described_state => described_state,
      :display_status => display_status,
      :awaiting_description => awaiting_description,
      :prominence => prominence,
      :law_used => law_used,
      :tags => tag_array,

      # not sure we need to make these, mainly anti-spam, admin params public
      # allow_new_responses_from
      # handle_rejected_responses
    }

    if deep
      if user
        ret[:user] = user.json_for_api
      else
        ret[:user_name] = user_name
      end
      ret[:public_body] = public_body.json_for_api
      ret[:info_request_events] = info_request_events.map { |e| e.json_for_api(false) }
    end
    ret
  end

  def purge_in_cache
    if AlaveteliConfiguration::varnish_host.present? && id
      # we only do this for existing info_requests (new ones have a nil id)
      path = url_for(:controller => 'request', :action => 'show', :url_title => url_title, :only_path => true, :locale => :none)
      req = PurgeRequest.find_by_url(path)
      if req.nil?
        req = PurgeRequest.new(:url => path,
                               :model => self.class.base_class.to_s,
                               :model_id => id)
      end
      req.save
    end
  end

  # This method updates the count columns of the PublicBody that
  # store the number of "not held", "to some extent successful" and
  # "both visible and classified" requests when saving or destroying
  # an InfoRequest associated with the body:
  def update_counter_cache
    PublicBody.skip_callback(:save, :after, :purge_in_cache)
    success_states = ['successful', 'partially_successful']
    basic_params = {
      :public_body_id => public_body_id,
      :prominence => 'normal'
    }
    [['info_requests_not_held_count', {:awaiting_description => false, :described_state => 'not_held'}],
     ['info_requests_successful_count', {:awaiting_description => false, :described_state => success_states}],
     ['info_requests_visible_classified_count', {:awaiting_description => false}],
     ['info_requests_visible_count', {}]].each do |column, extra_params|
       params = basic_params.clone.update extra_params
       public_body.send "#{column}=", InfoRequest.where(params).count
     end
     public_body.without_revision do
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
    [xapian_similar, xapian_similar_more]
  end

  def self.request_list(filters, page, per_page, max_results)
    query = InfoRequestEvent.make_query_from_params(filters)
    search_options = {
      :limit => 25,
      :offset => (page - 1) * per_page,
      :collapse_by_prefix => 'request_collapse' }

    xapian_object = search_events(query, search_options)
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
      max_count = 5
      search_options = {
        :limit => max_count,
        :collapse_by_prefix => 'request_title_collapse' }

      xapian_object = search_events(query, search_options)
      xapian_object.results
      request_events = xapian_object.results.map { |r| r[:model] }

      # If there are not yet enough successful requests, fill out the list with
      # other requests
      if request_events.count < max_count
        query = 'variety:sent'
        search_options[:limit] = max_count-request_events.count
        xapian_object = search_events(query, search_options)
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

    [request_events, request_events_all_successful]
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

  def accept_incoming?(email, raw_email_data)
    # See if new responses are prevented
    gatekeeper = ResponseGatekeeper.for(allow_new_responses_from, self)
    # Take action if the message looks like spam
    spam_checker = ResponseGatekeeper::SpamChecker.new

    # What rejected the email – the gatekeeper or the spam checker?
    response_rejector =
      if gatekeeper.allow?(email)
        if spam_checker.allow?(email)
          nil
        else
          spam_checker
        end
      else
        gatekeeper
      end

    # Figure out how to reject the mail if it was rejected
    response_rejection =
      if response_rejector
        ResponseRejection.
          for(response_rejector.rejection_action, self, email, raw_email_data)
      end

    will_be_rejected = (response_rejector && response_rejection) ? true : false

    if will_be_rejected && response_rejection.reject(response_rejector.reason)
      logger.info "Rejected incoming mail: #{ response_rejector.reason }"
      false
    else
      true
    end
  end

  def create_response!(email, raw_email_data, rejected_reason = nil)
    incoming_message = incoming_messages.build

    # To avoid a deadlock when simultaneously dealing with two
    # incoming emails that refer to the same InfoRequest, we
    # lock the row for update.
    with_lock do
      # TODO: These are very tightly coupled
      raw_email = RawEmail.new
      incoming_message.raw_email = raw_email
      incoming_message.save!
      raw_email.data = raw_email_data
      raw_email.save!

      self.awaiting_description = true

      params = { :incoming_message_id => incoming_message.id }
      params[:rejected_reason] = rejected_reason.to_s if rejected_reason
      log_event("response", params)

      save!
    end

    # for the "waiting_classification" index
    reindex_request_events

    incoming_message
  end

  def set_defaults
    begin
      if described_state.nil?
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

  def applicable_law
    begin
      LAW_USED_READABLE_DATA.fetch(law_used.to_sym)
    rescue KeyError
      raise "Unknown law used '#{law_used}'"
    end
  end

  def title_formatting
    if title && !MySociety::Validate.uses_mixed_capitals(title, 10)
      errors.add(:title, _('Please write the summary using a mixture of capital and lower case letters. This makes it easier for others to read.'))
    end
    if title && title =~ /^(FOI|Freedom of Information)\s*requests?$/i
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
  private_class_method :add_conditions_from_extra_params

  def self.search_events(query, opts = {})
    defaults = {
      :offset => 0,
      :limit => 20,
      :sort_by_prefix => 'created_at',
      :sort_by_ascending => true
    }
    ActsAsXapian::Search.new([InfoRequestEvent], query, defaults.merge(opts))
  end
  private_class_method :search_events
end
