# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: censor_rules
#
#  id                :integer          not null, primary key
#  info_request_id   :integer
#  user_id           :integer
#  public_body_id    :integer
#  text              :text             not null
#  replacement       :text             not null
#  last_edit_editor  :string(255)      not null
#  last_edit_comment :text             not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  regexp            :boolean
#

# models/censor_rule.rb:
# Stores alterations to remove specific data from requests.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class CensorRule < ActiveRecord::Base
  include ActiveModel::ForbiddenAttributesProtection
  include AdminColumn
  belongs_to :info_request
  belongs_to :user
  belongs_to :public_body

  # a flag to allow the require_user_request_or_public_body
  # validation to be skipped
  def allow_global
    warn %q([DEPRECATION] CensorRule#allow_global will be removed in 0.25)
    @allow_global
  end

  def allow_global=(value)
    warn %q([DEPRECATION] CensorRule#allow_global= will be removed in 0.25)
    @allow_global = value
  end

  validate :require_valid_regexp, :if => proc { |rule| rule.regexp? == true }

  validates_presence_of :text,
                        :replacement,
                        :last_edit_comment,
                        :last_edit_editor

  scope :global, -> {
    where(info_request_id: nil,
          user_id: nil,
          public_body_id: nil)
  }

  def apply_to_text(text_to_censor)
    return nil if text_to_censor.nil?
    text_to_censor.gsub(to_replace('UTF-8'), replacement)
  end

  def apply_to_text!(text_to_censor)
    warn %q([DEPRECATION] CensorRule#apply_to_text! will be removed in 0.25.
            Use the non-destructive CensorRule#apply_to_text instead).squish
    return nil if text_to_censor.nil?
    text_to_censor.gsub!(to_replace('UTF-8'), replacement)
  end

  def apply_to_binary(binary_to_censor)
    return nil if binary_to_censor.nil?
    binary_to_censor.gsub(to_replace('ASCII-8BIT')) { |match| match.gsub(single_char_regexp, 'x') }
  end

  def apply_to_binary!(binary_to_censor)
    warn %q([DEPRECATION] CensorRule#apply_to_binary! will be removed in 0.25.
            Use the non-destructive CensorRule#apply_to_binary instead).squish
    return nil if binary_to_censor.nil?
    binary_to_censor.gsub!(to_replace('ASCII-8BIT')) { |match| match.gsub(single_char_regexp, 'x') }
  end

  def is_global?
    info_request_id.nil? && user_id.nil? && public_body_id.nil?
  end

  private

  def single_char_regexp
    if String.method_defined?(:encode)
      Regexp.new('.'.force_encoding('ASCII-8BIT'))
    else
      Regexp.new('.', nil, 'N')
    end
  end

  def require_valid_regexp
    begin
      make_regexp('UTF-8')
    rescue RegexpError => e
      errors.add(:text, e.message)
    end
  end

  def to_replace(encoding)
    regexp? ? make_regexp(encoding) : encoded_text(encoding)
  end

  def encoded_text(encoding)
    String.method_defined?(:encode) ? text.dup.force_encoding(encoding) : text
  end

  def make_regexp(encoding)
    Regexp.new(encoded_text(encoding), Regexp::MULTILINE)
  end

end
