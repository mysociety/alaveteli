# == Schema Information
#
# Table name: incoming_messages
#
#  id                             :integer          not null, primary key
#  info_request_id                :integer          not null
#  created_at                     :datetime         not null
#  updated_at                     :datetime         not null
#  raw_email_id                   :integer          not null
#  cached_attachment_text_clipped :text
#  cached_main_body_text_folded   :text
#  cached_main_body_text_unfolded :text
#  subject                        :text
#  from_email_domain              :text
#  valid_to_reply_to              :boolean
#  last_parsed                    :datetime
#  from_name                      :text
#  sent_at                        :datetime
#  prominence                     :string           default("normal"), not null
#  prominence_reason              :text
#  from_email                     :text
#

# models/incoming_message.rb:
# An (email) message from really anybody to be logged with a request. e.g. A
# response from the public body.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

# TODO
# Move some of the (e.g. quoting) functions here into rblib, as they feel
# general not specific to IncomingMessage.

require 'rexml/document'
require 'zip'

class IncomingMessage < ApplicationRecord
  include MessageProminence
  include Taggable
  include Searchable

  # An IncomingMessage is intrinsically linked to its RawEmail. RawEmail just
  # holds the underlying plain text email and some basic methods for working
  # with it, whereas IncomingMessage coordinates extracting the useful data to
  # our domain records. This concern handles that basic relationship,
  # coordination and caching.
  include IncomingMessage::FromRawEmail

  # These concerns handle the specifics of parsing and working with the main
  # body and other attachments extracted from the RawEmail.
  include IncomingMessage::Attachments
  include IncomingMessage::MainBody

  # Ancillary behaviour
  include IncomingMessage::QuoteHandling
  include IncomingMessage::Refusals

  UnableToExtractAttachments = Class.new(StandardError)

  belongs_to :info_request,
             inverse_of: :incoming_messages,
             counter_cache: true

  has_one :user, through: :info_request

  has_many :outgoing_message_followups,
           inverse_of: :incoming_message_followup,
           foreign_key: 'incoming_message_followup_id',
           class_name: 'OutgoingMessage',
           dependent: :nullify

  # never really has many info_request_events, but could in theory
  has_many :info_request_events,
           dependent: :destroy,
           inverse_of: :incoming_message

  after_destroy :update_request
  after_update :update_request

  scope :pro, -> { joins(:info_request).merge(InfoRequest.pro) }

  delegate :erased?, :ensure_not_erased!, to: :raw_email, prefix: :raw_email

  delegate :apply_masks, to: :info_request

  searchable(
    index: {
      subject: "A",
      # get_body_for_indexing does not exactly match the censorship
      # applied on the public view.
      # We index the body of the email here instead of on FoiAttachment,
      # as most people think of it as part of the message rather than as
      # an attachment.
      ".get_body_for_indexing": "A",
      prominence_reason: "D"
    },
    admin_index: {
      from_email: "D",
      ".get_main_body_text_uncensored_for_indexing": "A"
    }
  )

  # We don't want to index the message until its body is cached,
  # as this forces caching the main body, which causes all sorts of
  # annoying side effects.
  def is_indexable?
    cached_main_body_text_folded.present?
  end

  # Given that there are in theory many info request events, a convenience
  # method for getting the response event.
  def response_event
    info_request_events.where(event_type: 'response').first
  end

  alias valid_to_reply_to? valid_to_reply_to

  # We can't redeliver when the RawEmail has been erased because redelivery
  # currently extracts the underlying data and creates a new response as if it
  # had been received in an email. Since we don't have the RawEmail data, this
  # will break.
  def redeliverable?
    !raw_email_erased?
  end

  # Public: The display name of the email sender with the associated
  # InfoRequest's censor rules applied.
  #
  # Example:
  #
  #   # Given a CensorRule that redacts the word 'Person':
  #
  #   incoming_message.from_name
  #   # => FOI Person
  #
  #   incoming_message.safe_from_name
  #   # => FOI [REDACTED]
  #
  # Returns a String
  def safe_from_name
    info_request.apply_censor_rules_to_text(from_name) if from_name
  end

  def specific_from_name?
    !safe_from_name.nil? && safe_from_name.strip != info_request.public_body.name.strip
  end

  def from_public_body?
    safe_from_name.nil? || (from_email_domain == info_request.public_body.request_email_domain)
  end

  # This method updates the cached column of the InfoRequest that
  # stores the last created_at date of relevant events
  # when updating an IncomingMessage associated with the request
  def update_request
    info_request.update_last_public_response_at
  end

  # Removes anything cached about the object in the database, and saves
  def clear_in_database_caches!
    self.cached_attachment_text_clipped = nil
    self.cached_main_body_text_unfolded = nil
    self.cached_main_body_text_folded = nil
    save!
  end

  # Returns text for indexing
  def get_text_for_indexing_full
    get_body_for_indexing + "\n\n" + get_attachment_text_full
  end

  # Used for excerpts in search results, when loading full text would be too slow
  def get_text_for_indexing_clipped
    get_body_for_indexing + "\n\n" + get_attachment_text_clipped
  end

  # Has message arrived "recently"?
  def recently_arrived
    (Time.zone.now - created_at) <= 3.days
  end

  def storage_keys
    keys = {}
    keys[:raw_email] = raw_email.storage_key
    keys[:attachments] = foi_attachments.map(&:storage_key)
    keys
  end
end
