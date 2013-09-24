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
    belongs_to :info_request
    belongs_to :user
    belongs_to :public_body

    # a flag to allow the require_user_request_or_public_body validation to be skipped
    attr_accessor :allow_global
    validate :require_user_request_or_public_body, :unless => proc{ |rule| rule.allow_global == true }
    validate :require_valid_regexp, :if => proc{ |rule| rule.regexp? == true }
    validates_presence_of :text

    scope :global, {:conditions => {:info_request_id => nil,
                                    :user_id => nil,
                                    :public_body_id => nil}}

    def require_user_request_or_public_body
        if self.info_request.nil? && self.user.nil? && self.public_body.nil?
            [:info_request, :user, :public_body].each do |a|
                errors.add(a, "Rule must apply to an info request, a user or a body")
            end
        end
    end

    def require_valid_regexp
        begin
            self.make_regexp()
        rescue RegexpError => e
            errors.add(:text, e.message)
        end
    end

    def make_regexp
        return Regexp.new(self.text, Regexp::MULTILINE)
    end

    def apply_to_text!(text)
        if text.nil?
            return nil
        end
        to_replace = regexp? ? self.make_regexp() : self.text
        text.gsub!(to_replace, self.replacement)
    end

    def apply_to_binary!(binary)
        if binary.nil?
            return nil
        end
        to_replace = regexp? ? self.make_regexp() : self.text
        binary.gsub!(to_replace){ |match| match.gsub(/./, 'x') }
    end

    def for_admin_column
        self.class.content_columns.each do |column|
          yield(column.human_name, self.send(column.name), column.type.to_s, column.name)
        end
    end

    def is_global?
        return true if (info_request_id.nil? && user_id.nil? && public_body_id.nil?)
        return false
    end

end
