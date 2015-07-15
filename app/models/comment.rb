# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: comments
#
#  id              :integer          not null, primary key
#  user_id         :integer          not null
#  comment_type    :string(255)      default("internal_error"), not null
#  info_request_id :integer
#  body            :text             not null
#  visible         :boolean          default(TRUE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  locale          :text             default(""), not null
#

# models/comments.rb:
# A comment by a user upon something.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class Comment < ActiveRecord::Base
  include AdminColumn
  strip_attributes!

  belongs_to :user
  belongs_to :info_request
  has_many :info_request_events # in practice only ever has one

  #validates_presence_of :user # breaks during construction of new ones :(
  validates_inclusion_of :comment_type, :in => [ 'request' ]
  validate :check_body_has_content,
    :check_body_uses_mixed_capitals

  scope :visible, where(:visible => true)

  after_save :event_xapian_update

  # When posting a new comment, use this to check user hasn't double
  # submitted.
  def self.find_existing(info_request_id, body)
    # TODO: can add other databases here which have regexp_replace
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      # Exclude spaces from the body comparison using regexp_replace
      regex_replace_sql = "regexp_replace(body, '[[:space:]]', '', 'g') = regexp_replace(?, '[[:space:]]', '', 'g')"
      Comment.where(["info_request_id = ? AND #{ regex_replace_sql }", info_request_id, body ]).first
    else
      # For other databases (e.g. SQLite) not the end of the world being
      # space-sensitive for this check
      Comment.where(:info_request_id => info_request_id, :body => body).first
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

  # So when takes changes it updates, or when made invisble it vanishes
  def event_xapian_update
    info_request_events.each { |event| event.xapian_mark_needs_index }
  end

  # Return body for display as HTML
  def get_body_for_html_display
    text = body.strip
    text = CGI.escapeHTML(text)
    text = MySociety::Format.make_clickable(text, :contract => 1)
    text = text.gsub(/\n/, '<br>')
    text.html_safe
  end

  private

  def check_body_has_content
    if body.empty? || body =~ /^\s+$/
      errors.add(:body, _("Please enter your annotation"))
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
