# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: info_request_events
#
#  id                  :integer          not null, primary key
#  info_request_id     :integer          not null
#  event_type          :text             not null
#  params_yaml         :text             not null
#  created_at          :datetime         not null
#  described_state     :string(255)
#  calculated_state    :string(255)
#  last_described_at   :datetime
#  incoming_message_id :integer
#  outgoing_message_id :integer
#  comment_id          :integer
#

# models/info_request_event.rb:
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class InfoRequestEvent < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include AdminColumn
  extend XapianQueries

  EVENT_TYPES = [
    'sent',
    'resent',
    'followup_sent',
    'followup_resent',

    'edit', # title etc. edited (in admin interface)
    'edit_outgoing', # outgoing message edited (in admin interface)
    'edit_comment', # comment edited (in admin interface)
    'destroy_incoming', # deleted an incoming message (in admin interface)
    'destroy_outgoing', # deleted an outgoing message (in admin interface)
    'redeliver_incoming', # redelivered an incoming message elsewhere (in admin interface)
    'edit_incoming', # incoming message edited (in admin interface)
    'move_request', # changed user or public body (in admin interface)
    'hide', # hid a request (in admin interface)
    'manual', # you did something in the db by hand
    'response',
    'comment',
    'status_update'
  ].freeze

  belongs_to :info_request
  validates_presence_of :info_request

  belongs_to :outgoing_message
  belongs_to :incoming_message
  belongs_to :comment

  has_one :request_classification

  has_many :user_info_request_sent_alerts, :dependent => :destroy
  has_many :track_things_sent_emails, :dependent => :destroy

  validates_presence_of :event_type

  after_create :update_request, :if => :response?

  def self.enumerate_event_types
    warn %q([DEPRECATION] InfoRequestEvent.enumerate_event_types will be removed
            in 0.26. Use InfoRequestEvent::EVENT_TYPES instead).squish
    EVENT_TYPES
  end

  validates_inclusion_of :event_type, :in => EVENT_TYPES

  # user described state (also update in info_request)
  validate :must_be_valid_state

  def must_be_valid_state
    if described_state and !InfoRequest.enumerate_states.include?(described_state)
      errors.add(:described_state, "is not a valid state")
    end
  end

  # Full text search indexing
  acts_as_xapian :texts => [ :search_text_main, :title ],
                 :values => [
                   [ :created_at, 0, "range_search", :date ], # for QueryParser range searches e.g. 01/01/2008..14/01/2008
                   [ :created_at_numeric, 1, "created_at", :number ], # for sorting
                   [ :described_at_numeric, 2, "described_at", :number ], # TODO: using :number for lack of :datetime support in Xapian values
                   [ :request, 3, "request_collapse", :string ],
                   [ :request_title_collapse, 4, "request_title_collapse", :string ],
                 ],
                 :terms => [ [ :calculated_state, 'S', "status" ],
                             [ :requested_by, 'B', "requested_by" ],
                             [ :requested_from, 'F', "requested_from" ],
                             [ :commented_by, 'C', "commented_by" ],
                             [ :request, 'R', "request" ],
                             [ :variety, 'V', "variety" ],
                             [ :latest_variety, 'K', "latest_variety" ],
                             [ :latest_status, 'L', "latest_status" ],
                             [ :waiting_classification, 'W', "waiting_classification" ],
                             [ :filetype, 'T', "filetype" ],
                             [ :tags, 'U', "tag" ]
                            ],
                 :if => :indexed_by_search?,
                 :eager_load => [ :outgoing_message, :comment, { :info_request => [ :user, :public_body, :censor_rules ] } ]

  def requested_by
    info_request.user_name_slug
  end

  def requested_from
    # acts_as_xapian will detect translated fields via Globalize and add all the
    # available locales to the index. But 'requested_from' is not translated directly,
    # although it relies on a translated field in PublicBody. Hence, we need to
    # manually add all the localized values to the index (Xapian can handle a list
    # of values in a term, btw)
    info_request.public_body.translations.map {|t| t.url_name}
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
    sibling_events(:reverse => true).each do |event|
      unless event.variety.blank?
        return event.variety
      end
    end
  end

  def latest_status
    sibling_events(:reverse => true).each do |event|
      unless event.calculated_state.blank?
        return event.calculated_state
      end
    end
  end

  def waiting_classification
    info_request.awaiting_description == true ? "yes" : "no"
  end

  def request_title_collapse
    info_request.url_title(:collapse => true)
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
    if message
      message.info_request = InfoRequest.find(message.info_request_id)
    end
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

  def indexed_by_search?
    if ['sent', 'followup_sent', 'response', 'comment'].include?(event_type)
      if !info_request.indexed_by_search?
        return false
      end
      if event_type == 'response' && !incoming_message.indexed_by_search?
        return false
      end
      if ['sent', 'followup_sent'].include?(event_type) && !outgoing_message.indexed_by_search?
        return false
      end
      if event_type == 'comment' && !comment.visible
        return false
      end
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

  # We store YAML version of parameters in the database
  def params=(params)
    # TODO: should really set these explicitly, and stop storing them in
    # here, but keep it for compatibility with old way for now
    if params[:incoming_message_id]
      self.incoming_message_id = params[:incoming_message_id]
    end
    if params[:outgoing_message_id]
      self.outgoing_message_id = params[:outgoing_message_id]
    end
    if params[:comment_id]
      self.comment_id = params[:comment_id]
    end
    self.params_yaml = params.to_yaml
  end

  def params
    param_hash = YAML.load(params_yaml)
    param_hash.each do |key, value|
      param_hash[key] = value.force_encoding('UTF-8') if value.respond_to?(:force_encoding)
    end
    param_hash
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
          old_params[$1.to_sym] = value.to_s.strip
        end
      elsif params.include?(("old_" + key).to_sym)
        new_params[key.to_sym] = value.to_s.strip
      else
        other_params[key.to_sym] = value.to_s.strip
      end
    end
    new_params.delete_if { |key, value| ignore.keys.include?(key) }
    {:new => new_params, :old => old_params, :other => other_params}
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

  # Display version of status
  def display_status
    if is_incoming_message?
      status = calculated_state
      return status.nil? ? _("Response") : InfoRequest.get_status_description(status)
    end

    if is_outgoing_message?
      status = calculated_state
      if status
        if status == 'internal_review'
          return _("Internal review request")
        end
        if status == 'waiting_response'
          return _("Clarification")
        end
        raise _("unknown status {{status}}", :status => status)
      end
      # TRANSLATORS: "Follow up" in this context means a further
      # message sent by the requester to the authority after
      # the initial request
      return _("Follow up")
    end

    raise _("display_status only works for incoming and outgoing messages right now")
  end

  def is_sent_sort?
    ['sent', 'resent'].include?(event_type)
  end

  def is_followup_sort?
    ['followup_sent', 'followup_resent'].include?(event_type)
  end

  def outgoing?
    ['sent', 'followup_sent'].include?(event_type)
  end

  def response?
    event_type == 'response'
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
    if prev_addr.nil? && curr_addr.nil?
      return true
    end
    if prev_addr.nil? || curr_addr.nil?
      return false
    end
    MailHandler.address_from_string(prev_addr) == MailHandler.address_from_string(curr_addr)
  end

  def json_for_api(deep, snippet_highlight_proc = nil)
    ret = {
      :id => id,
      :event_type => event_type,
      # params_yaml has possibly sensitive data in it, don't include it
      :created_at => created_at,
      :described_state => described_state,
      :calculated_state => calculated_state,
      :last_described_at => last_described_at,
      :incoming_message_id => incoming_message_id,
      :outgoing_message_id => outgoing_message_id,
      :comment_id => comment_id,

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
      self.last_described_at = Time.now
      save!
    end
  end

  private

  def sibling_events(opts = {})
    order = opts[:reverse] ? 'created_at DESC' : 'created_at'
    events = self.class.where(:info_request_id => info_request_id).order(order)
  end

end
