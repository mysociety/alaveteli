# == Schema Information
# Schema version: 70
#
# Table name: censor_rules
#
#  id                :integer         not null, primary key
#  info_request_id   :integer         
#  user_id           :integer         
#  public_body_id    :integer         
#  text              :text            not null
#  replacement       :text            not null
#  last_edit_editor  :string(255)     not null
#  last_edit_comment :text            not null
#  created_at        :datetime        not null
#  updated_at        :datetime        not null
#

# models/censor_rule.rb:
# Stores alterations to remove specific data from requests.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: censor_rule.rb,v 1.5 2009-01-26 12:12:17 francis Exp $

class CensorRule < ActiveRecord::Base
    belongs_to :info_request
    belongs_to :user
    belongs_to :public_body

    def apply_to_text(text)
        if text.nil?
            return nil
        end
        text.gsub!(self.text, self.replacement)
        return text
    end
    def apply_to_binary(binary)
        if binary.nil?
            return nil
        end
        replacement = self.text.gsub(/./, 'x')
        binary.gsub!(self.text, replacement)
        return binary
    end


    def validate
        if self.info_request.nil? && self.user.nil? && self.public_body.nil?
            errors.add("Censor must apply to an info request a user or a body; ")
        end
    end
end



