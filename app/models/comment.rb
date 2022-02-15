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
  include AdminColumn
  include Rails.application.routes.url_helpers
  include LinkToHelper

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

  scope :visible, lambda {
    joins(:info_request).
      merge(InfoRequest.is_searchable.except(:select)).
        where(visible: true)
  }

  scope :embargoed, lambda {
    joins(info_request: :embargo).
      where('embargoes.id IS NOT NULL').
      references(:embargoes)
  }

  scope :not_embargoed, lambda {
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

  def body
    ret = read_attribute(:body)
    return ret if ret.nil?
    ret = ret.strip
    # remove excess linebreaks that unnecessarily space it out
    ret = ret.gsub(/(?:\n\s*){2,}/, "\n\n")
    ret
  end

  def hidden?
    !visible?
  end

  def reindex_request_events
    info_request_events.find_each(&:xapian_mark_needs_index)
  end

  def event_xapian_update
    warn 'DEPRECATION: Comment#event_xapian_update will be removed in 0.42. ' \
         'It has been replaced with Comment#reindex_request_events'
    reindex_request_events
  end

  # Return body for display as HTML
  def get_body_for_html_display
    text = body.strip
    text = CGI.escapeHTML(text)
    text = MySociety::Format.make_clickable(text, contract: 1, nofollow: true)
    text = text.gsub(/\n/, '<br>')
    text.html_safe
  end

  def for_admin_column(complete = false)
    if complete
      columns = self.class.content_columns
    else
      columns = self.class.content_columns.map do |c|
        c if %w(body visible created_at updated_at).include?(c.name)
      end.compact
    end

    columns.each do |column|
      name = column.name
      yield(name.humanize, send(name), column.type.to_s, name)
    end
  end

  def for_admin_event_column(event)
    return unless event

    columns = event.for_admin_column { |name, value, type, column_name| }

    columns = columns.map do |c|
      c if %w(event_type params_yaml created_at).include?(c.name)
    end

    columns.compact.each do |column|
      yield(column.name.humanize,
            event.send(column.name),
            column.type.to_s,
            column.name)
    end
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

      RequestMailer.requires_admin(info_request, user, message).deliver_now

      info_request.
        log_event('report_comment',
                  comment_id: id,
                  editor: user,
                  reason: reason,
                  message: raw_message,
                  old_attention_requested: old_attention,
                  attention_requested: true)
    end
  end

  def last_report
    info_request_events.where(event_type: 'report_comment').last
  end

  def last_reported_at
    last_report.try(:created_at)
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
