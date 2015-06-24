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
    include AdminColumn
    belongs_to :info_request
    belongs_to :user
    belongs_to :public_body

    # a flag to allow the require_user_request_or_public_body
    # validation to be skipped
    attr_accessor :allow_global

    validate :require_user_request_or_public_body, :unless => proc { |rule| rule.allow_global == true }
    validate :require_valid_regexp, :if => proc { |rule| rule.regexp? == true }

    validates_presence_of :text,
                          :replacement,
                          :last_edit_comment,
                          :last_edit_editor

    scope :global, { :conditions => { :info_request_id => nil,
                                      :user_id => nil,
                                      :public_body_id => nil } }

    def apply_to_text(text_to_censor)
        return nil if text_to_censor.nil?
        text_to_censor.gsub(to_replace('UTF-8'), replacement)
    end

    def apply_to_text!(text_to_censor)
        return nil if text_to_censor.nil?
        text_to_censor.gsub!(to_replace('UTF-8'), replacement)
    end

    def apply_to_binary!(binary_to_censor)
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

    def require_user_request_or_public_body
        if info_request.nil? && user.nil? && public_body.nil?
            [:info_request, :user, :public_body].each do |a|
                errors.add(a, "Rule must apply to an info request, a user or a body")
            end
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
