# == Schema Information
# Schema version: 20220210114052
#
# Table name: comments
#
#  id                  :integer          not null, primary key
#  user_id             :integer          not null
#  info_request_id     :integer
#  body                :text             not null
#  visible             :boolean          default(TRUE), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  locale              :text             default(""), not null
#  attention_requested :boolean          default(FALSE), not null
#

# models/comments.rb:
# A comment by a user upon something.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class Comment < ApplicationRecord
  include Rails.application.routes.url_helpers
  include LinkToHelper

  DEFAULT_CREATION_RATE_LIMITS = {
    1 => 2.seconds,
    2 => 5.minutes,
    4 => 30.minutes,
    6 => 1.hour
  }.freeze

  cattr_accessor :creation_rate_limits,
                 instance_reader: false,
                 instance_writer: false,
                 instance_accessor: false,
                 default: DEFAULT_CREATION_RATE_LIMITS

  strip_attributes allow_empty: true

  belongs_to :user,
             inverse_of: :comments,
             counter_cache: true

  belongs_to :info_request,
             inverse_of: :comments

  has_many :info_request_events, # in practice only ever has one
           inverse_of: :comment,
           dependent: :destroy

  # validates_presence_of :user # breaks during construction of new ones :(
  validate :check_body_has_content,
           :check_body_uses_mixed_capitals

  scope :visible, -> {
    joins(:info_request).
      merge(InfoRequest.is_searchable.except(:select)).
        where(visible: true)
  }

  scope :embargoed, -> {
    joins(info_request: :embargo).
      where('embargoes.id IS NOT NULL').
      references(:embargoes)
  }

  scope :not_embargoed, -> {
    joins(:info_request).
      select('comments.*').
        joins('LEFT OUTER JOIN embargoes
               ON embargoes.info_request_id = info_requests.id').
          where('embargoes.id IS NULL').
            references(:embargoes)
  }

  after_save :reindex_request_events

  default_url_options[:host] = AlaveteliConfiguration.domain

  # When posting a new comment, use this to check user hasn't double
  # submitted.
  def self.find_existing(info_request_id, body)
    # TODO: can add other databases here which have regexp_replace
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      # Exclude spaces from the body comparison using regexp_replace
      regex_replace_sql = "regexp_replace(body, '[[:space:]]', '', 'g') = " \
                          "regexp_replace(?, '[[:space:]]', '', 'g')"

      args = ["info_request_id = ? AND #{ regex_replace_sql }",
              info_request_id,
              body]

      Comment.where(args).first
    else
      # For other databases (e.g. SQLite) not the end of the world being
      # space-sensitive for this check
      Comment.where(info_request_id: info_request_id, body: body).first
    end
  end

  def self.exceeded_creation_rate?(comments)
    comments = comments.reorder(created_at: :desc)

    creation_rate_limits.any? do |limit, duration|
      comments.where(created_at: duration.ago..).size >= limit
    end
  end

  def body
    ret = read_attribute(:body)
    return ret if ret.nil?

    ret = ret.strip
    # remove excess linebreaks that unnecessarily space it out
    ret = ret.gsub(/(?:\n\s*){2,}/, "\n\n")
    ret
  end

  def prominence
    hidden? ? 'hidden' : 'normal'
  end

  def hidden?
    !visible?
  end

  def reindex_request_events
    info_request_events.find_each(&:xapian_mark_needs_index)
  end

  # Return body for display as HTML
  def get_body_for_html_display
    text = body.strip
    text = CGI.escapeHTML(text)
    text = MySociety::Format.make_clickable(text, contract: 1, nofollow: true)
    text = text.gsub(/\n/, '<br>')
    text.html_safe
  end

  def report_reasons
    [_('Annotation contains defamatory material'),
     _('Annotation contains personal information'),
     _('Vexatious annotation')]
  end

  # Report this comment for administrator attention
  def report!(reason, message, user)
    old_attention = attention_requested
    self.attention_requested = true
    save!

    if attention_requested? && user
      raw_message = message.dup
      message = "Reason: #{reason}\n\n#{message}\n\n" \
                "The user wishes to draw attention to the " \
                "comment: #{comment_url(self)} " \
                "\nadmin: #{edit_admin_comment_url(self)}"

      RequestMailer.requires_admin(info_request, user, message).deliver_later

      info_request.log_event(
        'report_comment',
        comment_id: id,
        editor: user,
        reason: reason,
        message: raw_message,
        old_attention_requested: old_attention,
        attention_requested: true
      )
    end
  end

  def last_report
    info_request_events.where(event_type: 'report_comment').last
  end

  def last_reported_at
    last_report.try(:created_at)
  end

  def hide(editor:)
    ActiveRecord::Base.transaction do
      event_params = {
        comment_id: id,
        editor: editor.url_name,
        old_visible: visible?,
        visible: false
      }

      update!(visible: false)
      info_request.log_event('hide_comment', event_params)
    end
  end

  def destroy_and_log_event(event: {})
    return false unless destroy

    info_request.log_event(
      'destroy_comment',
      event.merge(
        comment: self,
        comment_user: user,
        comment_created_at: created_at,
        comment_updated_at: updated_at
      )
    )
  end

  def cached_urls
    [
      request_path(info_request),
      show_user_wall_path(url_name: user.url_name)
    ]
  end

  private

  def check_body_has_content
    if body.empty? || body =~ /^\s+$/
      errors.add(:body, _('Please enter your annotation'))
    end
  end

  def check_body_uses_mixed_capitals
    unless MySociety::Validate.uses_mixed_capitals(body)
      msg = _('Please write your annotation using a mixture of capital and ' \
              'lower case letters. This makes it easier for others to read.')
      errors.add(:body, msg)
    end
  end
end
