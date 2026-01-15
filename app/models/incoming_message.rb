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

  include IncomingMessage::Attachments
  include IncomingMessage::CacheAttributesFromRawEmail
  include IncomingMessage::QuoteHandling
  include IncomingMessage::Refusals

  UnableToExtractAttachments = Class.new(StandardError)

  belongs_to :info_request,
             inverse_of: :incoming_messages,
             counter_cache: true

  has_many :outgoing_message_followups,
           inverse_of: :incoming_message_followup,
           foreign_key: 'incoming_message_followup_id',
           class_name: 'OutgoingMessage',
           dependent: :nullify

  # never really has many info_request_events, but could in theory
  has_many :info_request_events,
           dependent: :destroy,
           inverse_of: :incoming_message

  belongs_to :raw_email,
             inverse_of: :incoming_message,
             dependent: :destroy

  after_destroy :update_request
  after_update :update_request

  scope :pro, -> { joins(:info_request).merge(InfoRequest.pro) }
  scope :unparsed, -> { where(last_parsed: nil) }

  cache_from_raw_email :subject, :sent_at,
                       :from_name, :from_email, :from_email_domain,
                       :valid_to_reply_to

  delegate :message_id, to: :raw_email
  delegate :multipart?, to: :raw_email
  delegate :parts, to: :raw_email

  # Given that there are in theory many info request events, a convenience
  # method for getting the response event.
  def response_event
    info_request_events.where(event_type: 'response').first
  end

  def parse_raw_email!
    # The following fields may be absent; we treat them as cached
    # values in case we want to regenerate them (due to mail
    # parsing bugs, etc).
    raise "Incoming message id=#{id} has no raw_email" if raw_email.nil?

    ActiveRecord::Base.transaction do
      extract_attachments
      self.sent_at = raw_email.date || created_at
      self.subject = raw_email.subject
      self.from_name = raw_email.from_name
      self.from_email = raw_email.from_email || ''
      self.from_email_domain = raw_email.from_email_domain || ''
      self.valid_to_reply_to = raw_email.valid_to_reply_to?
      self.last_parsed = Time.zone.now
      save!
    end
  end

  def parse_raw_email
    raise "Incoming message id=#{id} has no raw_email" if raw_email.nil?

    parse_raw_email! if last_parsed.nil?
  end

  alias valid_to_reply_to? valid_to_reply_to

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

  def apply_masks(text, content_type)
    mask_options = { censor_rules: info_request.applicable_censor_rules,
                     masks: info_request.masks }
    AlaveteliTextMasker.apply_masks(text, content_type, mask_options)
  end

  # Removes anything cached about the object in the database, and saves
  def clear_in_database_caches!
    self.cached_attachment_text_clipped = nil
    self.cached_main_body_text_unfolded = nil
    self.cached_main_body_text_folded = nil
    save!
  end

  # Internal function to cache two sorts of main body text.
  # Cached as loading raw_email can be quite huge, and need this for just
  # search results
  def _cache_main_body_text
    text = get_main_body_text_internal
    # Strip the uudecode parts from main text
    # - this also effectively does a .dup as well, so text mods don't alter original
    text = text.split(/^begin.+^`\n^end\n/m).join(" ")

    if text.size > 1_000_000 # 1 MB ish
      raise "main body text more than 1 MB, need to implement clipping like for attachment text, or there is some other MIME decoding problem or similar"
    end

    # apply masks for this message
    text = apply_masks(text, 'text/html') unless get_main_body_text_part&.locked?

    # Remove existing quoted sections
    folded_quoted_text = remove_lotus_quoting(text, 'FOLDED_QUOTED_SECTION')
    folded_quoted_text = IncomingMessage.remove_quoted_sections(folded_quoted_text, "FOLDED_QUOTED_SECTION")

    self.cached_main_body_text_unfolded = text.delete("\0")
    self.cached_main_body_text_folded = folded_quoted_text.delete("\0")
    save!
  end

  # Returns body text from main text part of email, converted to UTF-8, with uudecode removed,
  # emails and privacy sensitive things remove, censored, and folded to remove excess quoted text
  # (marked with FOLDED_QUOTED_SECTION)
  # TODO: returns a .dup of the text, so calling functions can in place modify it
  def get_main_body_text_folded
    _cache_main_body_text if cached_main_body_text_folded.nil?
    cached_main_body_text_folded
  end

  def get_main_body_text_unfolded
    _cache_main_body_text if cached_main_body_text_unfolded.nil?
    cached_main_body_text_unfolded
  end

  # Returns body text from main text part of email, converted to UTF-8
  def get_main_body_text_internal
    parse_raw_email
    main_part = get_main_body_text_part
    _convert_part_body_to_text(main_part)

  rescue FoiAttachment::MissingAttachment
    # occasionally the main body part gets rebuilt while being masked, we should
    # be able to just retry to get the new main body part instance from the db.
    retry
  end

  # Given a main text part, converts it to text
  def _convert_part_body_to_text(part)
    if part.nil?
      text = "[ Email has no body, please see attachments ]"
    else
      # whatever kind of attachment it is, get the UTF-8 encoded text
      text = part.body_as_text.string
      if part.content_type == 'text/html'
        # e.g. http://www.whatdotheyknow.com/request/35/response/177
        # TODO: This is a bit of a hack as it is calling a
        # convert to text routine.  Could instead call a
        # sanitize HTML one.
        text = MailHandler.get_attachment_text_one_file(part.content_type, text, "UTF-8")
      end
    end

    # Add an annotation if the text had to be scrubbed
    if part && part.body_as_text.scrubbed?
      text += _("\n\n[ {{site_name}} note: The above text was badly encoded, and has had strange characters removed. ]",
                site_name: site_name)
    end
    # Fix DOS style linefeeds to Unix style ones (or other later regexps won't work)
    text = text.gsub(/\r\n/, "\n")

    # Compress extra spaces down to save space, and to stop regular expressions
    # breaking in strange extreme cases. e.g. for
    # http://www.whatdotheyknow.com/request/spending_on_consultants
    text.gsub(/ +/, " ")
  end

  # Returns part which contains main body text, or nil if there isn't one,
  # from a set of foi_attachments. If the leaves parameter is empty or not
  # supplied, uses its own foi_attachments.
  def get_main_body_text_part(leaves=[])
    leaves = foi_attachments if leaves.empty?

    # Find first part which is text/plain or text/html
    # (We have to include HTML, as increasingly there are mail clients that
    # include no text alternative for the main part, and we don't want to
    # instead use the first text attachment
    # e.g. http://www.whatdotheyknow.com/request/list_of_public_authorties)
    leaves.each do |p|
      if (p.content_type == 'text/plain') || (p.content_type == 'text/html')
        return p
      end
    end

    # Otherwise first part which is any sort of text
    leaves.each do |p|
      return p if p.content_type.match(/^text/)
    end

    # ... or if none, consider first part
    p = leaves[0]
    # if it is a known type then don't use it, return no body (nil)
    if !p.nil? && AlaveteliFileTypes.mimetype_to_extension(p.content_type)
      # this is guess of case where there are only attachments, no body text
      # e.g. http://www.whatdotheyknow.com/request/cost_benefit_analysis_for_real_n
      return nil
    end

    # otherwise return it assuming it is text (sometimes you get things
    # like binary/octet-stream, or the like, which are really text - TODO: if
    # you find an example, put URL here - perhaps we should be always returning
    # nil in this case)
    p
  end

  # Returns body text as HTML with quotes flattened, and emails removed.
  def get_body_for_html_display(collapse_quoted_sections = true)
    # Find the body text and remove emails for privacy/anti-spam reasons
    text = get_main_body_text_unfolded

    # Remove quoted sections, adding HTML. TODO: The FOLDED_QUOTED_SECTION is
    # a nasty hack so we can escape other HTML before adding the unfold
    # links, without escaping them. Rather than using some proper parser
    # making a tree structure (I don't know of one that is to hand, that
    # works well in this kind of situation, such as with regexps).
    text = get_main_body_text_folded if collapse_quoted_sections
    text = MySociety::Format.simplify_angle_bracketed_urls(text)
    text = CGI.escapeHTML(text)
    text = MySociety::Format.make_clickable(text, contract: 1)

    # add a helpful link to email addresses and mobile numbers removed
    # by apply_masks
    email_pattern = Regexp.escape(_("email address"))
    mobile_pattern = Regexp.escape(_("mobile number"))
    text.gsub!(/\[(#{email_pattern}|#{mobile_pattern})\]/,
               '[<a href="/help/officers#mobiles">\1</a>]')

    text = handle_quoted_sections(text, collapse: collapse_quoted_sections)
    text = ActionController::Base.helpers.simple_format(text)
    text.html_safe
  end

  def get_body_for_indexing # rubocop:disable Naming/AccessorMethodName
    return '' if Ability.guest.cannot?(:read, get_main_body_text_part)

    get_body_for_quoting
  end

  # Returns text of email for using in quoted section when replying
  def get_body_for_quoting
    # Get the body text with emails and quoted sections removed
    text = get_main_body_text_folded.dup
    text.gsub!("FOLDED_QUOTED_SECTION", " ")
    text.strip!
    raise "internal error" if text.nil?

    text
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

  def locked?
    foi_attachments.locked.any?
  end

  def storage_keys
    keys = {}
    keys[:raw_email] = raw_email.storage_key
    keys[:attachments] = foi_attachments.map(&:storage_key)
    keys
  end
end
