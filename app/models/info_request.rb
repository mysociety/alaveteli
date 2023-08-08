# == Schema Information
# Schema version: 20220928093559
#
# Table name: info_requests
#
#  id                                    :integer          not null, primary key
#  title                                 :text             not null
#  user_id                               :integer
#  public_body_id                        :integer          not null
#  created_at                            :datetime         not null
#  updated_at                            :datetime         not null
#  described_state                       :string           not null
#  awaiting_description                  :boolean          default(FALSE), not null
#  prominence                            :string           default("normal"), not null
#  url_title                             :text             not null
#  law_used                              :string           default("foi"), not null
#  allow_new_responses_from              :string           default("anybody"), not null
#  handle_rejected_responses             :string           default("bounce"), not null
#  idhash                                :string           not null
#  external_user_name                    :string
#  external_url                          :string
#  attention_requested                   :boolean          default(FALSE)
#  comments_allowed                      :boolean          default(TRUE), not null
#  info_request_batch_id                 :integer
#  last_public_response_at               :datetime
#  reject_incoming_at_mta                :boolean          default(FALSE), not null
#  rejected_incoming_count               :integer          default(0)
#  date_initial_request_last_sent_at     :date
#  date_response_required_by             :date
#  date_very_overdue_after               :date
#  last_event_forming_initial_request_id :integer
#  use_notifications                     :boolean
#  last_event_time                       :datetime
#  incoming_messages_count               :integer          default(0)
#  public_token                          :string
#  prominence_reason                     :text
#

require 'digest/sha1'
require 'fileutils'

class InfoRequest < ApplicationRecord
  Guess = Struct.new(:info_request, :matched_value, :match_method).freeze
  OLD_AGE_IN_DAYS = 21.days

  include Rails.application.routes.url_helpers
  include AlaveteliPro::RequestSummaries
  include AlaveteliFeatures::Helpers
  include InfoRequest::BatchPagination
  include InfoRequest::PublicToken
  include InfoRequest::Sluggable
  include InfoRequest::TitleValidation
  include Taggable
  include Notable

  admin_columns exclude: %i[title url_title],
                include: %i[rejected_incoming_count]

  def self.admin_title
    'Request'
  end

  strip_attributes allow_empty: true
  strip_attributes only: [:title],
                   replace_newlines: true, collapse_spaces: true

  belongs_to :user,
             inverse_of: :info_requests,
             counter_cache: true

  validate :must_be_internal_or_external

  belongs_to :public_body,
             inverse_of: :info_requests,
             counter_cache: true
  belongs_to :info_request_batch,
             inverse_of: :info_requests

  validates_presence_of :public_body, message: N_("Please select an authority")

  has_many :info_request_events,
           -> { order(:created_at, :id) },
           inverse_of: :info_request,
           dependent: :destroy
  has_many :outgoing_messages,
           -> { order(:created_at) },
           inverse_of: :info_request,
           dependent: :destroy
  has_many :incoming_messages,
           -> { order(:created_at) },
           inverse_of: :info_request,
           dependent: :destroy
  has_many :user_info_request_sent_alerts,
           inverse_of: :info_request,
           dependent: :destroy
  has_many :track_things,
           -> { order(created_at: :desc) },
           inverse_of: :info_request,
           dependent: :destroy
  has_many :widget_votes,
           inverse_of: :info_request,
           dependent: :destroy
  has_many :citations,
           -> (info_request) { unscope(:where).for_request(info_request) },
           as: :citable,
           inverse_of: :citable,
           dependent: :destroy
  has_many :comments,
           -> { order(:created_at) },
           inverse_of: :info_request,
           dependent: :destroy
  has_many :censor_rules,
           -> { order(created_at: :desc) },
           inverse_of: :info_request,
           dependent: :destroy
  has_many :mail_server_logs,
           -> { order(:mail_server_log_done_id, :order) },
           inverse_of: :info_request,
           dependent: :destroy
  has_one :embargo,
          inverse_of: :info_request,
          class_name: 'AlaveteliPro::Embargo',
          dependent: :destroy

  has_many :foi_attachments, through: :incoming_messages

  has_many :project_submissions, class_name: 'Project::Submission'
  has_many :classification_project_submissions,
           -> { classification },
           class_name: 'Project::Submission'
  has_many :extraction_project_submissions,
           -> { extraction },
           class_name: 'Project::Submission'

  attr_reader :followup_bad_reason

  scope :internal, -> { where.not(user_id: nil) }
  scope :external, -> { where(user_id: nil) }

  scope :pro, ProQuery.new
  scope :is_public, Prominence::PublicQuery.new
  scope :is_searchable, Prominence::SearchableQuery.new
  scope :embargoed, Prominence::EmbargoedQuery.new
  scope :not_embargoed, Prominence::NotEmbargoedQuery.new
  scope :embargo_expiring, Prominence::EmbargoExpiringQuery.new
  scope :embargo_expired_today, Prominence::EmbargoExpiredTodayQuery.new
  scope :visible_to_requester, Prominence::VisibleToRequesterQuery.new
  scope :been_published, Prominence::BeenPublishedQuery.new

  scope :awaiting_response, State::AwaitingResponseQuery.new
  scope :response_received, State::ResponseReceivedQuery.new
  scope :clarification_needed, State::ClarificationNeededQuery.new
  scope :complete, State::CompleteQuery.new
  scope :other, State::OtherQuery.new
  scope :overdue, State::OverdueQuery.new
  scope :very_overdue, State::VeryOverdueQuery.new

  scope :for_project, Project::InfoRequestQuery.new

  scope :surveyable, Survey::InfoRequestQuery.new

  class << self
    alias in_progress awaiting_response
  end
  scope :action_needed, State::ActionNeededQuery.new
  scope :updated_before, ->(ts) { where('"info_requests"."updated_at" < ?', ts) }

  # user described state (also update in info_request_event, admin_request/edit.rhtml)
  validate :must_be_valid_state
  validates_inclusion_of :prominence, in: Prominence::VALUES

  validates_inclusion_of :law_used, in: Legislation.keys

  # who can send new responses
  validates_inclusion_of :allow_new_responses_from, in: [
    'anybody', # anyone who knows the request email address
    'authority_only', # only people from authority domains
    'nobody'
  ]
  # what to do with refused new responses
  validates_inclusion_of :handle_rejected_responses, in: [
    'bounce', # return them to sender
    'holding_pen', # put them in the holding pen
    'blackhole' # just dump them
  ]

  after_initialize :set_defaults
  before_create :set_use_notifications
  before_validation :compute_idhash
  before_validation :set_law_used, on: :create
  after_save :update_counter_cache
  after_update :reindex_request_events, if: :reindexable_attribute_changed?
  before_destroy :expire
  after_destroy :update_counter_cache

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

  # Public: Find by a list of incoming email addresses.
  # TODO: It would be better to make this return a chainable
  # ActiveRecord::Relation
  #
  # Examples:
  #
  #   InfoRequest.matching_incoming_email('request-1-ae63fb73@localhost')
  #   InfoRequest.matching_incoming_email(@array_of_email_addresses)
  #
  # Returns an Array
  def self.matching_incoming_email(emails)
    Array(emails).map { |email| find_by_incoming_email(email) }.compact
  end

  # Subset of states accepted via the API
  def self.allowed_incoming_states
    %w[
      waiting_response
      rejected
      successful
      partially_successful
    ]
  end

  def self.custom_states_loaded
    @@custom_states_loaded
  end

  # Public: Attempt to find InfoRequests by matching against extracted `id` and
  # `idhash` elements of an `incoming_email`.
  #
  # emails - A String email address or an Array of String email addresses.
  #
  # Returns an Array
  def self.guess_by_incoming_email(*emails)
    guesses = emails.flatten.reduce([]) do |memo, email|
      id, idhash = _extract_id_hash_from_email(email)
      id, idhash = _guess_idhash_from_email(email) if idhash.nil? || id.nil?
      memo << Guess.new(find_by_id(id), email, :id)
      memo << Guess.new(find_by_idhash(idhash), email, :idhash)
    end

    # Unique Guesses where we've found an `InfoRequest`
    guesses.select(&:info_request).uniq(&:info_request)
  end

  # Internal function used by guess_by_incoming_email
  def self._guess_idhash_from_email(incoming_email)
    incoming_email = incoming_email.downcase
    incoming_email =~ /request\-?(\w+)-?(\w{8})@/

    id = _id_string_to_i(_clean_idhash($1))
    id_hash = $2

    if id_hash.nil? && incoming_email.include?('@')
      # try to grab the last 8 chars of the local part of the address instead
      local_part = incoming_email[0..incoming_email.index('@')-1]
      id_hash =
        (_clean_idhash(local_part[-8..-1]) if local_part.length >= 8)
    end

    [id, id_hash]
  end

  # Internal function - attempts to convert a guessed id String from incoming
  # email addresses to an Integer. Returns nil if it fails to avoid accidentally
  # stripping trailing letters e.g. '123ab' should not match 123
  #
  # Returns an Integer
  def self._id_string_to_i(id_string)
    Integer(id_string) if id_string
  rescue ArgumentError
    nil
  end

  # Internal function used to clean the id_hash from incoming email addresses.
  # Converts l to 1, and o to 0. FOI officers quite often retype the email
  # address and make this kind of error.
  def self._clean_idhash(hash)
    return unless hash
    hash.gsub(/l/, "1").gsub(/o/, "0")
  end

  # Public: Attempt to find InfoRequests by matching against extracted `subject`
  # element of an `incoming_email`.
  #
  # subject_line - A String an email subject line
  # Returns an Array
  def self.guess_by_incoming_subject(subject_line)
    return [] unless subject_line

    # try to find a match on InfoRequest#title
    reply_format = InfoRequest.new(title: '').email_subject_followup
    requests_by_title = InfoRequest.left_joins(:incoming_messages).
      where(title: subject_line.gsub(/#{reply_format}/i, '').strip)

    # try to find a match on IncomingMessage#subject
    requests_by_subject = InfoRequest.left_joins(:incoming_messages).
      where(incoming_messages: {
              subject: [subject_line.gsub(/^Re: /i, ''), subject_line].uniq
            })

    requests = requests_by_title.or(requests_by_subject).
      distinct.
      where.not(url_title: 'holding_pen').
      limit(25)

    guesses = requests.each.reduce([]) do |memo, request|
      memo << Guess.new(request, subject_line, :subject)
    end

    # Unique Guesses where we've found an `InfoRequest`
    guesses.select(&:info_request).uniq(&:info_request)
  end

  # Internal function used by find_by_magic_email and guess_by_incoming_email
  def self._extract_id_hash_from_email(incoming_email)
    # Match case insensitively, FOI officers often write Request with capital R.
    incoming_email = incoming_email.downcase

    # The optional bounce- dates from when we used to have separate emails for the envelope from.
    # (that was abandoned because councils would send hand written responses to them, not just
    # bounce messages)
    incoming_email =~ /request-(?:bounce-)?([a-z0-9]+)-([a-z0-9]+)/

    id = _id_string_to_i($1)
    hash = _clean_idhash($2)

    [id, hash]
  end

  # When constructing a new request, use this to check user hasn't double submitted.
  # TODO: could have a date range here, so say only check last month's worth of new requests. If somebody is making
  # repeated requests, say once a quarter for time information, then might need to do that.
  # TODO: this *should* also check outgoing message joined to is an initial
  # request (rather than follow up)
  def self.find_existing(title, public_body_id, body)
    conditions = { title: title&.strip, public_body_id: public_body_id }

    InfoRequest.
      includes(:outgoing_messages).
        where(conditions).
          merge(OutgoingMessage.with_body(body)).
            references(:outgoing_messages).
              first
  end

  # The "holding pen" is a special request which stores incoming emails whose
  # destination request is unknown.
  def self.holding_pen_request
    ir = InfoRequest.find_by_url_title("holding_pen")
    if ir.nil?
      ir = InfoRequest.new(
        user: User.internal_admin_user,
        public_body: PublicBody.internal_admin_body,
        title: 'Holding pen',
        described_state: 'waiting_response',
        awaiting_description: false,
        prominence: 'hidden'
      )
      om = OutgoingMessage.new({
        status: 'ready',
        message_type: 'initial_request',
        body: 'This is the holding pen request. It shows responses that were sent to invalid addresses, and need moving to the correct request by an adminstrator.',
        last_sent_at: Time.zone.now,
        what_doing: 'normal_sort'

      })
      ir.outgoing_messages << om
      om.info_request = ir
      ir.save!
      ir.log_event(
        'sent',
        outgoing_message_id: om.id,
        email: ir.public_body.request_email
      )
    end
    ir
  end

  # states which require administrator action (hence email administrators
  # when they are entered, and offer state change dialog to them)
  def self.requires_admin_states
    %w(requires_admin error_message attention_requested)
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
      'gone_postal'                   => _("Handled by postal mail."),
      'internal_review'               => _("Awaiting internal review."),
      'error_message'                 => _("Delivery error"),
      'requires_admin'                => _("Unusual response."),
      'attention_requested'           => _("Reported for administrator attention."),
      'user_withdrawn'                => _("Withdrawn by the requester."),
      'vexatious'                     => _("Considered by administrators as " \
                                           "vexatious."),
      'not_foi'                       => _("Considered by administrators as " \
                                           "not an FOI request.")
    }
    if descriptions[status]
      descriptions[status]
    elsif respond_to?(:theme_display_status)
      theme_display_status(status)
    else
      raise _("unknown status {{status}}", status: status)
    end
  end

  def self.magic_email_for_id(prefix_part, id)
    magic_email = AlaveteliConfiguration.incoming_email_prefix
    magic_email += prefix_part + id.to_s
    magic_email += "-" + InfoRequest.hash_from_id(id)
    magic_email += "@" + AlaveteliConfiguration.incoming_email_domain
    magic_email
  end

  def self.build_from_attributes(info_request_atts, outgoing_message_atts, user=nil)
    info_request = new(info_request_atts)
    default_message_params = {
      status: 'ready',
      message_type: 'initial_request',
      what_doing: 'normal_sort'
    }

    attrs = outgoing_message_atts.merge(default_message_params)

    if attrs.respond_to?(:permit)
      attrs.permit(:body, :what_doing, :status, :message_type, :what_doing)
    end

    outgoing_message = OutgoingMessage.new(attrs)
    info_request.outgoing_messages << outgoing_message
    outgoing_message.info_request = info_request
    info_request.user = user
    info_request
  end

  def self.from_draft(draft)
    info_request = new(title: draft.title,
                       user: draft.user,
                       public_body: draft.public_body)
    info_request.outgoing_messages.new(body: draft.body,
                                       status: 'ready',
                                       message_type: 'initial_request',
                                       what_doing: 'normal_sort',
                                       info_request: info_request)
    if draft.embargo_duration
      info_request.embargo = AlaveteliPro::Embargo.new(
        embargo_duration: draft.embargo_duration,
        info_request: info_request
      )
    end
    info_request
  end

  def self.hash_from_id(id)
    Digest::SHA1.hexdigest(id.to_s + AlaveteliConfiguration.incoming_email_secret)[0,8]
  end

  # Used to find when event last changed
  def self.last_event_time_clause(event_type=nil, join_table=nil, join_clause=nil)
    event_type_clause = ''
    if event_type
      event_type_clause = " AND info_request_events.event_type = '#{event_type}'"
    end
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

  def self.where_old_unclassified(age_in_days=nil)
    age_in_days =
      if age_in_days
        age_in_days.days
      else
        OLD_AGE_IN_DAYS
      end

    where("awaiting_description = ?
          AND last_public_response_at < ?
          AND url_title != 'holding_pen'
          AND user_id IS NOT NULL",
          true, Time.zone.now - age_in_days)
  end

  def self.download_zip_dir
    File.join(Rails.root, "cache", "zips", Rails.env)
  end

  def self.reject_incoming_at_mta(options)
    query = InfoRequest.where(["updated_at < (now() -
                                interval ?)
                                AND allow_new_responses_from = 'nobody'
                                AND rejected_incoming_count >= ?
                                AND reject_incoming_at_mta = ?
                                AND url_title <> 'holding_pen'",
                                "#{options[:age_in_months]} months",
                                options[:rejection_threshold], false])
    yield query.pluck(:id) if block_given?

    if options[:dryrun]
      0
    else
      query.update_all(reject_incoming_at_mta: true)
    end
  end

  def self.requests_old_after_months
    AlaveteliConfiguration.restrict_new_responses_on_old_requests_after_months
  end

  def self.requests_very_old_after_months
    requests_old_after_months * 4
  end

  # This is called from cron regularly.
  def self.stop_new_responses_on_old_requests
    # 'old' months since last change to request, only allow new incoming
    # messages from authority domains
    InfoRequest
      .been_published
      .where(allow_new_responses_from: 'anybody')
      .where.not(url_title: 'holding_pen')
      .updated_before(requests_old_after_months.months.ago.to_date)
      .find_in_batches do |batch|
        batch.each do |info_request|
          old_allow_new_responses_from = info_request.allow_new_responses_from

          info_request.
            update_column(:allow_new_responses_from, 'authority_only')

          params =
            { old_allow_new_responses_from: old_allow_new_responses_from,
              allow_new_responses_from: info_request.allow_new_responses_from,
              editor: 'InfoRequest.stop_new_responses_on_old_requests' }

          info_request.log_event('edit', params)
        end
      end

    # 'very_old' months since last change to request, don't allow any new
    # incoming messages
    InfoRequest
      .been_published
      .where(allow_new_responses_from: %w[anybody authority_only])
      .where.not(url_title: 'holding_pen')
      .updated_before(requests_very_old_after_months.months.ago.to_date)
      .find_in_batches do |batch|
        batch.each do |info_request|
          old_allow_new_responses_from = info_request.allow_new_responses_from

          info_request.
            update_column(:allow_new_responses_from, 'nobody')

          params =
            { old_allow_new_responses_from: old_allow_new_responses_from,
              allow_new_responses_from: info_request.allow_new_responses_from,
              editor: 'InfoRequest.stop_new_responses_on_old_requests' }

          info_request.log_event('edit', params)
        end
      end
  end

  def self.request_list(filters, page, per_page, max_results)
    query = InfoRequestEvent.make_query_from_params(filters)
    search_options = {
      limit: 25,
      offset: (page - 1) * per_page,
      collapse_by_prefix: 'request_collapse' }

    xapian_object = search_events(query, search_options)
    list_results = xapian_object.results.map { |r| r[:model] }
    matches_estimated = xapian_object.matches_estimated
    show_no_more_than = [matches_estimated, max_results].min
    { results: list_results,
      matches_estimated: matches_estimated,
      show_no_more_than: show_no_more_than }
  end

  def self.recent_requests
    request_events = []
    request_events_all_successful = false
    # Get some successful requests
    begin
      query = 'variety:response (status:successful OR status:partially_successful)'
      max_count = 5
      search_options = {
        limit: max_count,
        collapse_by_prefix: 'request_title_collapse' }

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
        request_events.sort! { |e1,e2| e2.created_at <=> e1.created_at }
      else
        request_events_all_successful = true
      end
    rescue
      request_events = []
    end

    [request_events, request_events_all_successful]
  end

  def self.find_in_state(state)
    where(described_state: state).
      order(:last_event_time)
  end

  def self.log_overdue_events
    log_overdue_event_type('overdue')
  end

  def self.log_very_overdue_events
    log_overdue_event_type('very_overdue')
  end

  def self.log_overdue_event_type(event_type)
    date_field = case event_type
    when 'overdue'
      'date_response_required_by'
    when 'very_overdue'
      'date_very_overdue_after'
    else
      raise ArgumentError("Event type #{event_type} not handled")
    end

    query =
      where(["awaiting_description = ?
              AND described_state = ?
              AND #{date_field} < ?
              AND (SELECT id
              FROM info_request_events
              WHERE info_request_id = info_requests.id
              AND event_type = ?
              AND created_at > info_requests.#{date_field})
              IS NULL",
              false,
              'waiting_response',
              Time.zone.today,
              event_type])

    query.find_each(batch_size: 100) do |info_request|
      # Date to DateTime representing beginning of day
      created_at = info_request.send(date_field).beginning_of_day + 1.day
      event = info_request.log_event(
        event_type,
        { event_created_at: Time.zone.now },
        created_at: created_at
      )
      info_request.user.notify(event) if info_request.use_notifications?
    end

  end

  def self.request_sent_types
    %w(sent resent followup_sent followup_resent send_error)
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

  # Public: Overrides the ActiveRecord attribute accessor
  #
  # opts = Hash of options (default: {})
  #        :decorate - Wrap the string in a ProminenceCalculator decorator that
  #        has methods indicating whether the InfoRequest is public, searchable
  #        etc.
  # Returns a String or ProminenceCalculator
  def prominence(opts = {})
    decorate = opts.fetch(:decorate, false)
    if decorate
      Prominence::Calculator.new(self)
    else
      read_attribute(:prominence)
    end
  end

  # opts = Hash of options (default: {})
  # Returns a StateCalculator
  def state(_opts = {})
    State::Calculator.new(self)
  end

  def indexed_by_search?
    prominence(decorate: true).is_searchable?
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
      unless external_user_name.nil?
        errors.add(:external_user_name, "must be null for an internal request")
      end
      unless external_url.nil?
        errors.add(:external_url, "must be null for an internal request")
      end
    end
  end

  def is_external?
    external_url.nil? ? false : true
  end

  def user_name
    return external_user_name if is_external?
    user&.name
  end

  def from_name
    return external_user_name if is_external?
    outgoing_messages.first&.from_name || user_name
  end

  def safe_from_name
    return external_user_name if is_external?
    apply_censor_rules_to_text(from_name)
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
    is_external? ? { name: user_name || _("Anonymous user") } : user.json_for_api
  end

  @@custom_states_loaded = false
  begin
    require 'customstates'
    include InfoRequestCustomStates
    @@custom_states_loaded = true
  rescue LoadError, NameError
  end

  def reindex_request_events
    info_request_events.find_each(&:xapian_mark_needs_index)
  end

  # Force reindex when tag string changes
  alias orig_tag_string= tag_string=
  def tag_string=(tag_string)
    ret = self.orig_tag_string=(tag_string)
    reindex_request_events
    ret
  end

  def expire(options={})
    # Clear any attachment masked_at timestamp, forcing attachments to be
    # reparsed
    clear_attachment_masks!

    # Clear out cached entries, by removing files from disk (the built in
    # Rails fragment cache made doing this and other things too hard)
    foi_fragment_cache_directories.each { |dir| FileUtils.rm_rf(dir) }

    # Remove any download zips
    FileUtils.rm_rf(download_zip_dir)

    # Remove the database caches of body / attachment text (the attachment text
    # one is after privacy rules are applied)
    clear_in_database_caches! unless options[:preserve_database_cache]

    # also force a search reindexing (so changed text reflected in search)
    reindex_request_events
  end

  def clear_attachment_masks!
    foi_attachments.update_all(masked_at: nil)
  end

  # Removes anything cached about the object in the database, and saves
  def clear_in_database_caches!
    incoming_messages.each(&:clear_in_database_caches!)
  end

  def update_last_public_response_at
    last_public_event = get_last_public_response_event
    if last_public_event
      self.last_public_response_at = last_public_event.created_at
    else
      self.last_public_response_at = nil
    end
    save!
  end

  # Remove spaces from ends (for when used in emails etc.)
  # Needed for legacy reasons, even though we call strip_attributes now
  def title
    _title = read_attribute(:title)
    _title.strip! if _title
    _title
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
      law_used_full: legislation.to_s(:full),
      title: (html ? title : title.html_safe))
  end

  def email_subject_followup(opts = {})
    incoming_message = opts.fetch(:incoming_message, nil)
    html = opts.fetch(:html, true)
    if incoming_message.nil? || !incoming_message.valid_to_reply_to? || !incoming_message.subject
      'Re: ' + email_subject_request(html: html)
    elsif incoming_message.subject.match(/^Re:/i)
      incoming_message.subject
    else
      'Re: ' + incoming_message.subject
    end
  end

  def legislation
    return Legislation.find!(law_used) if law_used
    public_body&.legislation || Legislation.default
  end

  def find_existing_outgoing_message(body)
    outgoing_messages.with_body(body).first
  end

  # Has this email already been received here? Based just on message id.
  def already_received?(email, _raw_email_data)
    message_id = email.message_id
    raise "No message id for this message" if message_id.nil?

    incoming_messages.each do |im|
      return true if message_id == im.message_id
    end

    false
  end

  def receive(email, raw_email_data, *args)
    defaults = { override_stop_new_responses: false,
                 rejected_reason: nil,
                 source: :internal }

    opts = if args.first.is_a?(Hash)
      defaults.merge(args.shift)
    else
      defaults
    end

    if receive_mail_from_source? opts[:source]
      # Is this request allowing responses?
      accepted =
        if opts[:override_stop_new_responses]
          true
        else
          accept_incoming?(email, raw_email_data)
        end

      if accepted
        incoming_message =
          create_response!(email, raw_email_data, opts[:rejected_reason])

        # Notify the user that a new response has been received, unless the
        # request is external
        unless is_external?
          if use_notifications?
            info_request_event = info_request_events.find_by(
              event_type: 'response',
              incoming_message_id: incoming_message.id
            )
            user.notify(info_request_event)
          else
            RequestMailer.new_response(self, incoming_message).deliver_now
          end
        end
      end
    end
  end

  # Called when outgoing_messages are sent to ensure that the request
  # is not closed during an active discussion or an internal review
  def reopen_to_new_responses
    update(allow_new_responses_from: 'anybody', reject_incoming_at_mta: false)
  end

  # An annotation (comment) is made
  def add_comment(body, user)
    comment = Comment.new
    ActiveRecord::Base.transaction do
      comment.body = body
      comment.user = user
      comment.info_request = self
      comment.save!

      log_event('comment', comment_id: comment.id)
      save!
    end
    comment
  end

  def requires_admin?
    self.class.requires_admin_states.include?(described_state)
  end

  # Report this request for administrator attention
  def report!(reason, message, user)
    ActiveRecord::Base.transaction do
      log_event(
        'report_request',
        request_id: id,
        editor: user,
        reason: reason,
        message: message,
        old_attention_requested: attention_requested,
        attention_requested: true
      )

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
        RequestMailer.requires_admin(self, set_by, message).deliver_now
      end
    end

    unless set_by.nil? || is_actual_owning_user?(set_by) || described_state == 'attention_requested'
      RequestMailer.
        old_unclassified_updated(self).deliver_now unless is_external?
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
    Time.zone.now.strftime("%Y-%m-%d") > date_very_overdue_after.strftime("%Y-%m-%d")
    return 'waiting_response_overdue' if
    Time.zone.now.strftime("%Y-%m-%d") > date_response_required_by.strftime("%Y-%m-%d")
    'waiting_response'
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
    info_request_events.reverse.each do |event|
      event.xapian_mark_needs_index # we need to reindex all events in order to update their latest_* terms
      if curr_state.nil?
        curr_state = event.described_state if event.described_state
      end

      if curr_state && event.event_type == 'response'
        event.set_calculated_state!(curr_state)

        if event.last_described_at.nil? # TODO: actually maybe this isn't needed
          event.last_described_at = Time.zone.now
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
      elsif curr_state && (%w[edit status_update].include? event.event_type)
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

  # Find last InfoRequestEvent which  was:
  # -- sent at all
  # -- OR the same message was resent
  # -- OR the public body requested clarification, and a follow up was sent
  def last_event_forming_initial_request
    info_request_event_id = read_attribute(:last_event_forming_initial_request_id)
    last_sent = if info_request_event_id
      InfoRequestEvent.find_by_id(info_request_event_id)
    else
      calculate_last_event_forming_initial_request
    end

    if last_sent.nil?
      raise "internal error, last_event_forming_initial_request gets nil for " \
            "request #{ id } outgoing messages count " \
            "#{ outgoing_messages.size } all events: " \
            "#{ info_request_events.to_yaml }"
    end

    last_sent
  end

  def calculate_last_event_forming_initial_request
    # TODO: This can be removed when last_event_forming_initial_request_id has
    # been populated for all requests

    expecting_clarification = false
    last_sent = nil
    info_request_events.each do |event|
      if event.described_state == 'waiting_clarification'
        expecting_clarification = true
      end

      if self.class.request_sent_types.include?(event.event_type)
        if last_sent.nil?
          last_sent = event
        elsif event.event_type == 'resent' ||
              (event.event_type == 'send_error' &&
               event.outgoing_message.message_type == 'initial_request')
          last_sent = event
        elsif expecting_clarification && event.event_type == 'followup_sent'
          # TODO: this needs to cope with followup_resent, which it doesn't.
          # Not really easy to do, and only affects cases where followups
          # were resent after a clarification.
          last_sent = event
          expecting_clarification = false
        end
      end
    end
    last_sent
  end

  # Log an event to the history of some things that have happened to this request
  def log_event(type, params, options = {})
    event = info_request_events.create!(event_type: type, params: params)
    set_due_dates(event) if event.resets_due_dates?
    if options[:created_at]
      event.update_column(:created_at, options[:created_at])
    end
    if !last_event_time || (event.created_at > last_event_time)
      update_column(:last_event_time, event.created_at)
    end
    event
  end

  def set_due_dates(sent_event)
    self.last_event_forming_initial_request_id = sent_event.id
    self.date_initial_request_last_sent_at = sent_event.created_at.to_date
    self.date_response_required_by = calculate_date_response_required_by
    self.date_very_overdue_after = calculate_date_very_overdue_after
    save!
  end

  # TODO: once date_initial_request_sent_at is populated for all
  # requests, this can be removed
  # The last time that the initial request was sent/resent
  def date_initial_request_last_sent_at
    date = read_attribute(:date_initial_request_last_sent_at)
    return date.to_date if date
    calculate_date_initial_request_last_sent_at
  end

  # TODO: once date_initial_request_sent_at is populated for all
  # requests, this can be removed
  def calculate_date_initial_request_last_sent_at
    last_sent = last_event_forming_initial_request
    last_sent.outgoing_message.last_sent_at.to_date
  end

  def late_calculator
    @late_calculator ||= DefaultLateCalculator.new
  end

  # TODO: once date_response_required_by is populated for all
  # requests, this can be removed
  def date_response_required_by
    date = read_attribute(:date_response_required_by)
    return date if date
    calculate_date_response_required_by
  end

  def calculate_date_response_required_by
    Holiday.due_date_from(date_initial_request_last_sent_at,
                          late_calculator.reply_late_after_days,
                          AlaveteliConfiguration.working_or_calendar_days)
  end

  # TODO: once date_very_overdue_after is populated for all
  # requests, this can be removed
  def date_very_overdue_after
    date = read_attribute(:date_very_overdue_after)
    return date if date
    calculate_date_very_overdue_after
  end

  def calculate_date_very_overdue_after
    Holiday.due_date_from(date_initial_request_last_sent_at,
                          late_calculator.reply_very_late_after_days,
                          AlaveteliConfiguration.working_or_calendar_days)
  end

  def last_embargo_set_event
    info_request_events.
      where(event_type: 'set_embargo').
        reorder(created_at: :desc).
          first
  end

  def last_embargo_expire_event
    info_request_events.
      where(event_type: 'expire_embargo').
        reorder(created_at: :desc).
          first
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
      # TRANSLATORS: Please don't use double quotes (") in this translation
      # or it will break the site's ability to send emails to authorities!
      _("{{law_used_short}} requests at {{public_body}}",
        law_used_short: legislation,
        public_body: public_body.short_or_long_name),
        recipient_email)
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
    if get_last_public_response_event
      get_last_public_response_event.incoming_message
    end
  end

  def public_outgoing_events
    info_request_events.select { |e| e.outgoing? && e.outgoing_message.is_public? }
  end

  # The last public outgoing message
  def get_last_public_outgoing_event
    public_outgoing_events.last
  end

  # Text from the the initial request, for use in summary display
  def initial_request_text
    return '' if outgoing_messages.empty?
    body_opts = { censor_rules: applicable_censor_rules }
    first_message = outgoing_messages.first
    first_message.is_public? ? first_message.get_text_for_indexing(true, body_opts) : ''
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

  # Public: The most recent InfoRequestEvent.
  #
  # Returns an InfoRequestEvent or nil
  def last_event
    info_request_events.last
  end

  def last_update_hash
    Digest::SHA1.hexdigest(info_request_events.last.created_at.to_i.to_s + updated_at.to_i.to_s)
  end

  # Get previous email sent to
  def get_previous_email_sent_to(info_request_event)
    last_email = nil
    info_request_events.each do |e|
      if ((info_request_event.is_sent_sort? && e.is_sent_sort?) || (info_request_event.is_followup_sort? && e.is_followup_sort?)) && e.outgoing_message_id == info_request_event.outgoing_message_id
        break if e.id == info_request_event.id
        last_email = e.params[:email]
      end
    end
    last_email
  end

  def display_status(cached_value_ok=false)
    InfoRequest.get_status_description(calculate_status(cached_value_ok))
  end

  # Called by incoming_email - and used to be called to generate separate
  # envelope from address until we abandoned it.
  def magic_email(prefix_part)
    raise "id required to create a magic email" unless id
    InfoRequest.magic_email_for_id(prefix_part, id)
  end

  def compute_idhash
    self.idhash = InfoRequest.hash_from_id(id)
  end

  def foi_fragment_cache_directories
    # return stub path so admin can expire it
    directories = []
    path = File.join("request", request_dirs)
    foi_cache_path = File.expand_path(File.join(Rails.root, 'cache', 'views'))
    directories << File.join(foi_cache_path, path)
    AlaveteliLocalization.available_locales.each do |locale|
      directories << File.join(foi_cache_path, locale, path)
    end

    directories
  end

  def is_followupable?(incoming_message)
    if is_external?
      @followup_bad_reason = "external"
      false
    elsif !OutgoingMailer.is_followupable?(self, incoming_message)
      @followup_bad_reason = if public_body.is_requestable?
        "unexpected followupable inconsistency"
      else
        public_body.not_requestable_reason
      end
      false
    else
      @followup_bad_reason = nil
      true
    end
  end

  def postal_email
    if who_can_followup_to.empty?
      public_body.request_email
    else
      who_can_followup_to[-1][1]
    end
  end

  def postal_email_name
    if who_can_followup_to.empty?
      public_body.name
    else
      who_can_followup_to[-1][0]
    end
  end

  def request_dirs
    first_three_digits = id.to_s[0..2]
    File.join(first_three_digits.to_s, id.to_s)
  end

  def download_zip_dir
    File.join(InfoRequest.download_zip_dir, "download", request_dirs)
  end

  def make_zip_cache_path(user)
    # The zip file varies depending on user because it can include different
    # messages depending on whether the user can access hidden or
    # requester_only messages. We name it appropriately, so that every user
    # with the right permissions gets a file with only the right things in.
    cache_file_dir = File.join(InfoRequest.download_zip_dir,
                               "download",
                               request_dirs,
                               last_update_hash)
    cache_file_suffix = zip_cache_file_suffix(user)
    File.join(cache_file_dir, "#{url_title}#{cache_file_suffix}.zip")
  end

  def zip_cache_file_suffix(user)
    # Simple short circuit for requests where everything is public
    if all_correspondence_is_public?
      ""
    # If the user can view hidden things, they can view anything, so no need
    # to go any further
    elsif user&.view_hidden?
      "_hidden"
    # If the user can't view hidden things, but owns the request, they can
    # see more than the public, so they get requester_only
    elsif is_owning_user?(user)
      "_requester_only"
    # Everyone else can only see public stuff, which is the default case
    else
      ""
    end
  end

  def reason_to_be_unhappy?
    classified? && State.unhappy.include?(calculate_status)
  end

  def classified?
    !awaiting_description?
  end

  def is_old_unclassified?
    !is_external? && awaiting_description && url_title != 'holding_pen' && get_last_public_response_event &&
      Time.zone.now > get_last_public_response_event.created_at + OLD_AGE_IN_DAYS
  end

  # List of incoming messages to followup, by unique email
  def who_can_followup_to(skip_message = nil)
    ret = []
    done = {}
    if skip_message
      if (email = OutgoingMailer.email_for_followup(self, skip_message))
        done[email.downcase] = 1
      end
    end
    incoming_messages.reverse.each do |incoming_message|
      next if incoming_message == skip_message
      incoming_message.safe_from_name

      next unless incoming_message.is_public?

      email = OutgoingMailer.email_for_followup(self, incoming_message)
      name = OutgoingMailer.name_for_followup(self, incoming_message)

      unless done.include?(email.downcase)
        ret += [[name, email, incoming_message.id]]
      end
      done[email.downcase] = 1
    end

    unless done.include?(public_body.request_email.downcase)
      ret += [[public_body.name, public_body.request_email, nil]]
    end
    done[public_body.request_email.downcase] = 1

    ret.reverse
  end

  # Get the list of censor rules that apply to this request
  def applicable_censor_rules
    applicable_rules = [censor_rules, CensorRule.global]
    applicable_rules << public_body.censor_rules unless public_body.blank?
    applicable_rules << user.censor_rules if user
    applicable_rules.flatten
  end

  def apply_censor_rules_to_text(text)
    applicable_censor_rules.
      reduce(text) { |t, rule| rule.apply_to_text(t) }
  end

  def apply_censor_rules_to_binary(text)
    applicable_censor_rules.
      reduce(text) { |t, rule| rule.apply_to_binary(t) }
  end

  def apply_masks(text, content_type)
    mask_options = { censor_rules: applicable_censor_rules,
                     masks: masks }
    AlaveteliTextMasker.apply_masks(text, content_type, mask_options)
  end

  # Masks we apply to text associated with this request convert email addresses
  # we know about into textual descriptions of them
  def masks
    masks = [{ to_replace: incoming_email,
               replacement: _('[FOI #{{request}} email]', request: id.to_s) },
             { to_replace: AlaveteliConfiguration.contact_email,
               replacement: _("[{{site_name}} contact email]",
                              site_name: site_name) }]
    if public_body.is_followupable?
      masks << { to_replace: public_body.request_email,
                 replacement: _("[{{public_body}} request email]",
                                   public_body: public_body.short_or_long_name) }
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

  def all_correspondence_is_public?
    prominence(decorate: true).is_public? &&
      incoming_messages.all?(&:is_public?) &&
      outgoing_messages.all?(&:is_public?)
  end

  def json_for_api(deep)
    ret = {
      id: id,
      url_title: url_title,
      title: title,
      created_at: created_at,
      updated_at: updated_at,
      described_state: described_state,
      display_status: display_status,
      awaiting_description: awaiting_description,
      prominence: prominence,
      law_used: law_used,
      tags: tag_array

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

  # This method updates the count columns of the PublicBody that
  # store the number of "not held", "to some extent successful" and
  # "both visible and classified" requests when saving or destroying
  # an InfoRequest associated with the body:
  def update_counter_cache(body = public_body)
    body.update_counter_cache
  end

  def similar_cache_key
    "request/similar/#{id}"
  end

  # Get requests that have similar important terms
  def similar_requests(limit=10)
    ids, more = similar_ids(limit)
    [InfoRequest.includes(public_body: :translations).where(id: ids), more]
  end

  # Get the ids of similar requests, and whether there are more
  def similar_ids(limit=10)
    Rails.cache.fetch(similar_cache_key, expires_in: 3.days) do
      ids = []
      xapian_similar_more = false
      begin
        xapian_similar =
          ActsAsXapian::Similar.new([InfoRequestEvent],
                                    info_request_events,
                                    limit: limit,
                                    collapse_by_prefix: 'request_collapse')
        xapian_similar_more = (xapian_similar.matches_estimated > limit)
        ids = xapian_similar.results.map do |result|
          result[:model].info_request_id
        end
      rescue
      end
      [ids, xapian_similar_more]
    end
  end

  def move_to_public_body(destination_public_body, opts = {})
    return nil unless destination_public_body.try(:persisted?)
    old_body = public_body
    editor = opts.fetch(:editor)

    attrs = { public_body: destination_public_body }

    if destination_public_body
      attrs[:law_used] = destination_public_body.legislation.key
    end

    return_val = if update(attrs)
                   log_event(
                     'move_request',
                     editor: editor,
                     public_body_url_name: public_body.url_name,
                     old_public_body_url_name: old_body.url_name
                   )

                   reindex_request_events

                   public_body
                 end

    # HACK: Manually reset counter caches
    # https://github.com/rails/rails/issues/10865
    old_body.class.reset_counters(old_body.id, :info_requests)
    update_counter_cache(old_body)
    public_body.class.reset_counters(public_body.id, :info_requests)
    update_counter_cache
    return_val
  end

  def move_to_user(destination_user, opts = {})
    return nil unless destination_user.try(:persisted?)
    old_user = user
    editor = opts.fetch(:editor)

    return_val = if update(user: destination_user)
                   log_event(
                     'move_request',
                     editor: editor,
                     user_url_name: user.url_name,
                     old_user_url_name: old_user.url_name
                   )

                   reindex_request_events

                   user
                 end

    # HACK: Manually reset counter caches
    # https://github.com/rails/rails/issues/10865
    old_user.class.reset_counters(old_user.id, :info_requests)
    user.class.reset_counters(user.id, :info_requests)
    return_val
  end

  # Is the request currently embargoed?
  #
  # Returns Boolean
  def embargoed?
    embargo.present?
  end

  # Is the attached embargo expiring soon?
  #
  # Returns boolean
  def embargo_expiring?
    embargo ? embargo.expiring_soon? : false
  end

  # Has a previously attached embargo expired?
  #
  # Returns boolean
  def embargo_expired?
    if !embargo && last_embargo_expire_event
      true
    else
      false
    end
  end

  # Is the attached embargo still present but has reached its publication date
  #
  # Returns boolean
  def embargo_pending_expiry?
    embargo ? embargo.expired? : false
  end

  # @see RequestSummaries#should_summarise?
  def should_summarise?
    info_request_batch_id.blank?
  end

  # Requests in a batch should update their parent batch request when they
  # are updated.
  #
  # @see RequestSummaries#should_update_parent_summary?
  def should_update_parent_summary?
    info_request_batch_id.present?
  end

  # @see RequestSummaries#request_summary_parent
  def request_summary_parent
    if info_request_batch_id.blank?
      nil
    else
      info_request_batch
    end
  end

  # @see RequestSummaries#request_summary_body
  def request_summary_body
    outgoing_messages.any? ? outgoing_messages.first.body : ""
  end

  # @see RequestSummaries#request_summary_public_body_names
  def request_summary_public_body_names
    public_body.name unless public_body.blank?
  end

  # @see RequestSummaries#request_summary_categories
  def request_summary_categories
    categories = []
    if embargo_expiring?
      categories << AlaveteliPro::RequestSummaryCategory.embargo_expiring
    end
    # A request with no events is in the process of being sent (probably
    # having been created within our tests rather than in real code) and will
    # error if we try to get the phase, skip it for now because it'll be saved
    # when it's sent and trigger this code again anyway.
    if last_event_forming_initial_request_id.present?
      phase_slug = state.phase.to_s
      phase = AlaveteliPro::RequestSummaryCategory.find_by(slug: phase_slug)
      categories << phase unless phase.blank?
    end
    categories
  end

  def holding_pen_request?
    return true if url_title == 'holding_pen'
    self == self.class.holding_pen_request
  end

  def latest_refusals
    incoming_messages.select(&:refusals?).last&.refusals || []
  end

  private

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
      offset: 0,
      limit: 20,
      sort_by_prefix: 'created_at',
      sort_by_ascending: true
    }
    ActsAsXapian::Search.new([InfoRequestEvent], query, defaults.merge(opts))
  end
  private_class_method :search_events

  def receive_mail_from_source?(source)
    if source == :internal
      true
    elsif feature_enabled?(:accept_mail_from_anywhere)
      true
    elsif user.features.enabled?(:accept_mail_from_poller)
      source == :poller
    else
      source == :mailin
    end
  end

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
      # update without changing the updated_at field
      update_column(:rejected_incoming_count, rejected_incoming_count.next)
      logger.info "Rejected incoming mail: #{ response_rejector.reason } request: #{ id }"
      false
    else
      true
    end
  end

  def create_response!(_email, raw_email_data, rejected_reason = nil)
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

      unless described_state == 'user_withdrawn'
        self.awaiting_description = true
      end

      params = { incoming_message_id: incoming_message.id }
      params[:rejected_reason] = rejected_reason.to_s if rejected_reason
      log_event('response', params)

      save!
    end

    # for the "waiting_classification" index
    reindex_request_events

    incoming_message
  end

  # Returns index of last event which is described or nil if none described.
  def index_of_last_described_event
    info_request_events.reverse.each_with_index do |event, index|
      if event.described_state
        reverse_index = info_request_events.size - 1 - index
        return reverse_index
      end
    end
    nil
  end

  def set_defaults
    self.described_state = 'waiting_response' if described_state.nil?
  rescue ActiveModel::MissingAttributeError
    # this should only happen on Model.exists? call. It can be safely ignored.
    # See http://www.tatvartha.com/2011/03/activerecordmissingattributeerror-missing-attribute-a-bug-or-a-features/
  end

  def set_law_used
    return if law_used_changed?
    self.law_used = public_body.legislation.key if public_body
  end

  def set_use_notifications
    if use_notifications.nil?
      self.use_notifications = user &&
                               user.features.enabled?(:notifications) && \
                               info_request_batch_id.present?
    end
    true
  end

  def must_be_valid_state
    unless State.all.include?(described_state)
      errors.add(:described_state, "is not a valid state")
    end
  end

  # If the URL name has changed, then all request: queries will break unless
  # we update index for every event. Also reindex if prominence changes.
  def reindexable_attribute_changed?
    %i[url_title prominence user_id].any? do |attr|
      saved_change_to_attribute?(attr)
    end
  end
end
