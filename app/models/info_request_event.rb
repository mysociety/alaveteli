# == Schema Information
# Schema version: 20230127132719
#
# Table name: info_request_events
#
#  id                  :integer          not null, primary key
#  info_request_id     :integer          not null
#  event_type          :text             not null
#  created_at          :datetime         not null
#  described_state     :string
#  calculated_state    :string
#  last_described_at   :datetime
#  incoming_message_id :integer
#  outgoing_message_id :integer
#  comment_id          :integer
#  updated_at          :datetime
#  params              :jsonb
#

# models/info_request_event.rb:
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class InfoRequestEvent < ApplicationRecord
  extend XapianQueries

  EVENT_TYPES = [
    'sent',
    'resent',
    'followup_sent',
    'followup_resent',
    'edit', # title etc. edited (in admin interface)
    'edit_outgoing', # outgoing message edited (in admin interface)
    'edit_comment', # comment edited (in admin interface)
    'hide_comment', # comment hidden by admin
    'report_comment', # comment reported for admin attention by user
    'report_request', # a request reported for admin attention by user
    'destroy_incoming', # deleted an incoming message (in admin interface)
    'destroy_outgoing', # deleted an outgoing message (in admin interface)
    'redeliver_incoming', # redelivered an incoming message elsewhere (in admin interface)
    'edit_incoming', # incoming message edited (in admin interface)
    'edit_attachment', # attachment edited (in admin interface)
    'move_request', # changed user or public body (in admin interface)
    'hide', # hid a request (in admin interface)
    'manual', # you did something in the db by hand
    'response', # an incoming message is received
    'comment', # an annotation is added
    'status_update', # someone updates the status of the request
    'overdue', # the request becomes overdue
    'very_overdue', # the request becomes very overdue
    'embargo_expiring', # an embargo is about to expire
    'expire_embargo', # an embargo on the request expires
    'set_embargo', # an embargo is added or extended
    'send_error', # an error during sending
    'refusal_advice', # the results of completing the refusal advice wizard
    'public_token' # has the shareable public token been generated or not
  ].freeze

  belongs_to :info_request,
             inverse_of: :info_request_events

  validates_presence_of :info_request

  belongs_to :outgoing_message,
             inverse_of: :info_request_events
  belongs_to :incoming_message,
             inverse_of: :info_request_events
  belongs_to :comment,
             inverse_of: :info_request_events

  has_one :request_classification,
          inverse_of: :info_request_event

  has_many :user_info_request_sent_alerts,
           inverse_of: :info_request_event,
           dependent: :destroy
  has_many :track_things_sent_emails,
           inverse_of: :info_request_event,
           dependent: :destroy
  has_many :notifications,
           inverse_of: :info_request_event,
           dependent: :destroy

  validates_presence_of :event_type

  before_save(if: :only_editing_prominence_to_hide?) do
    self.event_type = "hide"
  end
  after_create :update_request, if: :response?

  after_commit -> { info_request.create_or_update_request_summary },
                  on: [:create]

  validates_inclusion_of :event_type, in: EVENT_TYPES

  # user described state (also update in info_request)
  validate :must_be_valid_state

  def must_be_valid_state
    if described_state and !InfoRequest::State.all.include?(described_state)
      errors.add(:described_state, "is not a valid state")
    end
  end

  attr_accessor :no_xapian_reindex

  # Full text search indexing
  acts_as_xapian texts: [ :search_text_main, :title ],
                 values: [
                   [ :created_at, 0, "range_search", :date ], # for QueryParser range searches e.g. 01/01/2008..14/01/2008
                   [ :created_at_numeric, 1, "created_at", :number ], # for sorting
                   [ :described_at_numeric, 2, "described_at", :number ], # TODO: using :number for lack of :datetime support in Xapian values
                   [ :request, 3, "request_collapse", :string ],
                   [ :request_title_collapse, 4, "request_title_collapse", :string ],
                 ],
                 terms: [ [ :calculated_state, 'S', "status" ],
                             [ :requested_by, 'B', "requested_by" ],
                             [ :requested_from, 'F', "requested_from" ],
                             [ :commented_by, 'C', "commented_by" ],
                             [ :request, 'R', "request" ],
                             [ :variety, 'V', "variety" ],
                             [ :latest_variety, 'K', "latest_variety" ],
                             [ :latest_status, 'L', "latest_status" ],
                             [ :waiting_classification, 'W', "waiting_classification" ],
                             [ :filetype, 'T', "filetype" ],
                             [ :tags, 'U', "tag" ],
                             [ :request_public_body_tags, 'X', "request_public_body_tag" ] ],
                 if: :indexed_by_search?,
                 eager_load: [ :outgoing_message, :comment, { info_request: [ :user, :public_body, :censor_rules ] } ]

  def self.count_of_hides_by_week
    where(event_type: "hide").group("date(date_trunc('week', created_at))").count.sort
  end

  def requested_by
    info_request.user_name_slug
  end

  def requested_from
    # acts_as_xapian will detect translated fields via Globalize and add all the
    # available locales to the index. But 'requested_from' is not translated directly,
    # although it relies on a translated field in PublicBody. Hence, we need to
    # manually add all the localized values to the index (Xapian can handle a list
    # of values in a term, btw)
    info_request.public_body.translations.map { |t| t.url_name }
  end

  def commented_by
    if event_type == 'comment'
      comment.user.url_name
    else
      ''
    end
  end

  def request
    info_request.url_title
  end

  def latest_variety
    sibling_events(reverse: true).each do |event|
      return event.variety unless event.variety.blank?
    end
  end

  def latest_status
    sibling_events(reverse: true).each do |event|
      return event.calculated_state unless event.calculated_state.blank?
    end
  end

  def waiting_classification
    info_request.awaiting_description == true ? "yes" : "no"
  end

  def request_title_collapse
    info_request.url_title(collapse: true)
  end

  def described_at
    # For responses, people might have RSS feeds on searches for type of
    # response (e.g. successful) in which case we want to date sort by
    # when the responses was described as being of the type. For other
    # types, just use the create at date.
    last_described_at || created_at
  end

  def described_at_numeric
    # format it here as no datetime support in Xapian's value ranges
    described_at.strftime("%Y%m%d%H%M%S")
  end

  def created_at_numeric
    # format it here as no datetime support in Xapian's value ranges
    created_at.strftime("%Y%m%d%H%M%S")
  end

  def incoming_message_selective_columns(fields)
    message = IncomingMessage.select("#{ fields }, incoming_messages.info_request_id").
      joins('INNER JOIN info_request_events ON incoming_messages.id = incoming_message_id').
      where('info_request_events.id = ?', id)

    message = message[0]
    message.info_request = InfoRequest.find(message.info_request_id) if message
    message
  end

  def get_clipped_response_efficiently
    # TODO: this ugly code is an attempt to not always load all the
    # columns for an incoming message, which can be *very* large
    # (due to all the cached text).  We care particularly in this
    # case because it's called for every search result on a page
    # (to show the search snippet). Actually, we should review if we
    # need all this data to be cached in the database at all, and
    # then we won't need this horrid workaround.
    message = incoming_message_selective_columns("cached_attachment_text_clipped, cached_main_body_text_folded")
    clipped_body = message.cached_main_body_text_folded
    clipped_attachment = message.cached_attachment_text_clipped
    if clipped_body.nil? || clipped_attachment.nil?
      # we're going to have to load it anyway
      text = incoming_message.get_text_for_indexing_clipped
    else
      text = clipped_body.gsub("FOLDED_QUOTED_SECTION", " ").strip + "\n\n" + clipped_attachment
    end
    text + "\n\n"
  end

  # clipped = true - means return shorter text. It is used for snippets fore
  # performance reasons. Xapian will take the full text.
  def search_text_main(clipped = false)
    text = ''
    if event_type == 'sent'
      text = text + outgoing_message.get_text_for_indexing + "\n\n"
    elsif event_type == 'followup_sent'
      text = text + outgoing_message.get_text_for_indexing + "\n\n"
    elsif event_type == 'response'
      if clipped
        text = text + get_clipped_response_efficiently
      else
        text = text + incoming_message.get_text_for_indexing_full + "\n\n"
      end
    elsif event_type == 'comment'
      text = text + comment.body + "\n\n"
    else
      # nothing
    end
    text
  end

  def title
    if event_type == 'sent'
      info_request.title
    else
      ''
    end
  end

  def filetype
    if event_type == 'response'
      unless incoming_message
        raise "event type is 'response' but no incoming message for event id #{id}"
      end

      incoming_message.get_present_file_extensions
    else
      ''
    end
  end

  def tags
    # this returns an array of strings, each gets indexed as separate term by acts_as_xapian
    info_request.tag_array_for_search
  end

  def request_public_body_tags
    info_request.public_body.tag_array_for_search
  end

  def indexed_by_search?
    if %w[sent followup_sent response comment].include?(event_type)
      return false unless info_request.indexed_by_search?
      if event_type == 'response' && !incoming_message.indexed_by_search?
        return false
      end
      if %w[sent followup_sent].include?(event_type) && !outgoing_message.indexed_by_search?
        return false
      end
      return false if event_type == 'comment' && !comment.visible
      return true
    end
    false
  end

  def variety
    event_type
  end

  def visible
    if event_type == 'comment'
      comment.visible
    else
      true
    end
  end

  def params=(new_params)
    super(params_for_jsonb(new_params))

    # TODO: should really set these explicitly, and stop storing them in
    # here, but keep it for compatibility with old way for now
    if params[:incoming_message]
      self.incoming_message = params[:incoming_message]
    end
    if params[:outgoing_message]
      self.outgoing_message = params[:outgoing_message]
    end
    self.comment = params[:comment] if params[:comment]
  end

  # A hash to lazy load Global ID reference models
  class Params < Hash
    def [](key)
      value = super
      return value unless value.is_a?(Hash) && value[:gid]

      instance = GlobalID::Locator.locate(value[:gid])
      self[key] = instance
    end
  end

  def params
    params_jsonb = super
    Params[params_jsonb.deep_symbolize_keys] if params_jsonb
  end

  def params_diff
    # split out parameters into old/new diffs, and other ones
    old_params = {}
    new_params = {}
    other_params = {}
    ignore = {}
    for key, value in params
      key = key.to_s
      if key.match(/^old_(.*)$/)
        if params[$1.to_sym] == value
          ignore[$1.to_sym] = ''
        else
          old_params[$1.to_sym] = value
        end
      elsif params.include?(("old_" + key).to_sym)
        new_params[key.to_sym] = value
      else
        other_params[key.to_sym] = value
      end
    end
    new_params.delete_if { |key, value| ignore.keys.include?(key) }
    {new: new_params, old: old_params, other: other_params}
  end

  def is_incoming_message?
    incoming_message_id? or (incoming_message if new_record?)
  end

  def is_outgoing_message?
    outgoing_message_id? or (outgoing_message if new_record?)
  end

  def is_comment?
    comment_id? or (comment if new_record?)
  end

  def resets_due_dates?
     is_request_sending? || is_clarification?
  end

  def is_request_sending?
    %w[sent resent].include?(event_type) ||
    (event_type == 'send_error' &&
     outgoing_message.message_type == 'initial_request')
  end

  def is_clarification?
    waiting_clarification = false
    # A follow up is a clarification only if it's the first
    # follow up when the request is in a state of
    # waiting for clarification
    previous_events(reverse: true).each do |event|
      if event.described_state == 'waiting_clarification'
        waiting_clarification = true
        break
      end
      break if event.event_type == 'followup_sent'
    end
    waiting_clarification && event_type == 'followup_sent'
  end

  # Public: Checks to see if any subsequent event now resets due dates
  # on the request and resets them if so
  def recheck_due_dates
    subsequent_events.each do |event|
      info_request.set_due_dates(event) if event.resets_due_dates?
    end
  end

  # Display version of status
  def display_status
    if is_incoming_message?
      status = calculated_state
      return status.nil? ? _("Response") : InfoRequest.get_status_description(status)
    end

    if is_outgoing_message?
      status = calculated_state
      if status
        return _("Internal review request") if status == 'internal_review'
        return _("Clarification") if status == 'waiting_response'
        raise _("unknown status {{status}}", status: status)
      end
      # TRANSLATORS: "Follow up" in this context means a further
      # message sent by the requester to the authority after
      # the initial request
      return _("Follow up")
    end

    raise _("display_status only works for incoming and outgoing messages right now")
  end

  def is_sent_sort?
    %w[sent resent].include?(event_type)
  end

  def is_followup_sort?
    %w[followup_sent followup_resent].include?(event_type)
  end

  def outgoing?
    %w[sent followup_sent].include?(event_type)
  end

  def response?
    event_type == 'response'
  end

  def only_editing_prominence_to_hide?
    event_type == 'edit' &&
      params_diff[:new].keys == [:prominence] &&
      params_diff[:old][:prominence] == "normal" &&
      %w(hidden requester_only backpage).include?(params_diff[:new][:prominence])
  end

  # This method updates the cached column of the InfoRequest that
  # stores the last created_at date of relevant events
  # when saving or destroying an InfoRequestEvent associated with the request
  def update_request
    info_request.update_last_public_response_at
  end

  def same_email_as_previous_send?
    prev_addr = info_request.get_previous_email_sent_to(self)
    curr_addr = params[:email]
    return true if prev_addr.nil? && curr_addr.nil?
    return false if prev_addr.nil? || curr_addr.nil?
    MailHandler.address_from_string(prev_addr) == MailHandler.address_from_string(curr_addr)
  end

  def json_for_api(deep, snippet_highlight_proc = nil)
    ret = {
      id: id,
      event_type: event_type,
      # params has possibly sensitive data in it, don't include it
      created_at: created_at,
      described_state: described_state,
      calculated_state: calculated_state,
      last_described_at: last_described_at,
      incoming_message_id: incoming_message_id,
      outgoing_message_id: outgoing_message_id,
      comment_id: comment_id,

      # TODO: would be nice to add links here, but alas the
      # code to make them is in views only. See views/request/details.html.erb
      # perhaps can call with @template somehow
    }

    if is_incoming_message? || is_outgoing_message?
      ret[:display_status] = display_status
    end

    if snippet_highlight_proc
      ret[:snippet] = snippet_highlight_proc.call(search_text_main(true))
    end

    if deep
      ret[:info_request] = info_request.json_for_api(false)
      ret[:public_body] = info_request.public_body.json_for_api
      ret[:user] = info_request.user_json_for_api
    end

    ret
  end

  def set_calculated_state!(state)
    unless calculated_state == state
      self.calculated_state = state
      self.last_described_at = Time.zone.now
      save!
    end
  end

  private

  def previous_events(opts = {})
    order = opts[:reverse] ? 'created_at DESC' : 'created_at'
    events = self.
               class.
                 where(info_request_id: info_request_id).
                   where('created_at < ?', created_at).
                     order(order)

  end

  def subsequent_events(opts = {})
    order = opts[:reverse] ? 'created_at DESC' : 'created_at'
    events = self.
               class.
                 where(info_request_id: info_request_id).
                   where('created_at > ?', created_at).
                     order(order)
  end

  def sibling_events(opts = {})
    order = opts[:reverse] ? 'created_at DESC' : 'created_at'
    events = self.class.where(info_request_id: info_request_id).order(order)
  end

  def params_for_jsonb(params)
    params.inject({}) do |memo, (k, v)|
      key = k.to_s

      # look for keys ending in `_id` and attempt to map to a Ruby class
      key = key.sub(/_id$/, '')
      if Regexp.last_match
        klass_str = key.classify
        klass = klass_str.safe_constantize
        klass ||= "AlaveteliPro::#{klass_str}".safe_constantize
        klass ||= InfoRequest if klass_str == 'Request'
        if klass
          # attempt to load the object by ID
          object = klass.find_by(id: v)

          # if object can't be loading, eg, deleted from DB, manually build
          # ID/type hash
          value = { gid: "gid://app/#{klass}/#{v}" } unless object

        else
          # without a class, probably not a application model, EG email message
          # ID, so revert the change to the key to re-add the `_id`
          key = k
        end
      end

      object ||= v if v.is_a?(ApplicationRecord)
      if object
        # if we have an object, map to a ID/type hash - including version if
        # present
        value = { gid: object.to_global_id.to_s }
        value[:version] = object.version if object.respond_to?(:version)
      end

      memo[key.to_sym] = value || v
      memo
    end
  end
end
