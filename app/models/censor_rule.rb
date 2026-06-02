# == Schema Information
#
# Table name: censor_rules
#
#  id                :integer          not null, primary key
#  text              :text             not null
#  replacement       :text             not null
#  last_edit_editor  :string           not null
#  last_edit_comment :text             not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  regexp            :boolean          default(FALSE), not null
#  case_sensitive    :boolean          default(TRUE), not null
#  ignore_diacritics :boolean          default(FALSE), not null
#  censorable_type   :string
#  censorable_id     :bigint
#

# models/censor_rule.rb:
# Stores alterations to remove specific data from requests.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class CensorRule < ApplicationRecord
  DEFAULT_CANNED_REPLACEMENTS = [
    _('[Personally Identifiable Information removed]'),
    _('[name removed]'),
    _('[extraneous material removed]'),
    _('[potentially defamatory material removed]'),
    _('[extraneous and potentially defamatory material removed]')
  ].freeze

  belongs_to :censorable,
             polymorphic: true,
             optional: true

  validate :require_valid_regexp,
           if: -> { regexp? || !case_sensitive? || ignore_diacritics? }

  validate :regexp_ignore_diacritics,
           if: -> { regexp? && ignore_diacritics? }

  validates_presence_of :text,
                        :replacement,
                        :last_edit_comment,
                        :last_edit_editor

  scope :info_request, -> { where(censorable_type: 'InfoRequest') }
  scope :public_body, -> { where(censorable_type: 'PublicBody') }
  scope :user, -> { where(censorable_type: 'User') }
  scope :global, -> { where(censorable_id: nil, censorable_type: nil) }

  cattr_accessor :canned_replacements,
                 instance_writer: false,
                 default: DEFAULT_CANNED_REPLACEMENTS.dup

  after_commit :expire_requests

  def apply_to_text(text_to_censor)
    return nil if text_to_censor.nil?

    text_to_censor.gsub(to_replace('UTF-8'), replacement)
  end

  def apply_to_binary(binary_to_censor)
    return nil if binary_to_censor.nil?

    binary_to_censor.gsub(to_replace(binary_to_censor.encoding)) do |match|
      match.gsub(single_char_regexp) { |m| 'x' * m.bytesize }
    end
  end

  def is_global?
    censorable_id.nil? && censorable_type.nil?
  end

  def expire_requests
    case censorable
    when InfoRequest
      InfoRequest::ExpireJob.perform_later(censorable)
      NotifyCacheJob.perform_later(censorable)
    when User, PublicBody
      InfoRequest::ExpireJob.perform_later(censorable, :info_requests)
    else
      InfoRequest::ExpireJob.perform_later(InfoRequest, :all)
    end
  end

  def censorable_requests
    censorable&.info_requests || InfoRequest.unscoped
  end

  private

  def single_char_regexp
    Regexp.new('.'.force_encoding('ASCII-8BIT'))
  end

  def require_valid_regexp
    make_regexp('UTF-8')
  rescue RegexpError => e
    errors.add(:text, e.message)
  end

  def to_replace(encoding)
    if regexp? || !case_sensitive? || ignore_diacritics?
      make_regexp(encoding)
    else
      encoded_text(encoding)
    end
  end

  def encoded_text(encoding)
    text.dup.force_encoding(encoding)
  end

  def make_regexp(encoding)
    pattern =
      if ignore_diacritics?
        diacritic_expander.expand(encoded_text(encoding))
      else
        encoded_text(encoding)
      end

    pattern = Regexp.escape(pattern) unless regexp? || ignore_diacritics?

    ::Warning.with_raised_warnings do
      Regexp.new(pattern, regexp_options)
    end
  rescue RaisedWarning => e
    raise RegexpError, e.message.split('warning: ').last.chomp
  end

  def regexp_options
    options = 0
    options |= Regexp::IGNORECASE unless case_sensitive?
    options |= Regexp::MULTILINE if regexp?
    options
  end

  def diacritic_expander
    DiacriticExpander.new(case_sensitive: case_sensitive?)
  end

  def regexp_ignore_diacritics
    msg = 'Cannot use regexp and ignore diacritics option together'
    errors.add(:text, msg)
  end
end
