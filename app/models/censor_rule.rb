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
  include CensorRule::CannedReplacements
  include CensorRule::Diacritics
  include CensorRule::Expiry
  include CensorRule::Polymorphic
  include CensorRule::Regexp

  validates_presence_of :text,
                        :replacement,
                        :last_edit_comment,
                        :last_edit_editor

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

  private

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

  def single_char_regexp
    ::Regexp.new('.'.force_encoding('ASCII-8BIT'))
  end
end
