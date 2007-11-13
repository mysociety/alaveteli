# models/incoming_message.rb:
# An (email) message from really anybody to be logged with a request. e.g. A
# response from the public body.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: incoming_message.rb,v 1.4 2007-11-13 10:22:14 francis Exp $

class IncomingMessage < ActiveRecord::Base
    belongs_to :info_request
    validates_presence_of :info_request

    validates_presence_of :raw_data

    # Return the structured TMail::Mail object
    # Documentation at http://i.loveruby.net/en/projects/tmail/doc/
    def mail
        if @mail.nil?
            @mail = TMail::Mail.parse(self.raw_data)
            @mail.base64_decode
        end
        @mail
    end

    # Return date mail was sent
    def sent_at
        # Use date it arrived (created_at) if mail itself doesn't have Date: header
        self.mail.date || self.created_at
    end
end


