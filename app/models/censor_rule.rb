# models/censor_rule.rb:
# Stores alterations to remove specific data from requests.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: censor_rule.rb,v 1.1 2008-10-27 18:18:30 francis Exp $

class CensorRule < ActiveRecord::Base
    belongs_to :info_request
    belongs_to :user
    belongs_to :public_body

    def apply_to_text(text)
        text.gsub!(self.text, self.replacement)
        return text
    end
    def apply_to_binary(binary)
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



