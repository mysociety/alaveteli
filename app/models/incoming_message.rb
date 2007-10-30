# models/incoming_message.rb:
# An (email) message from really anybody to be logged with a request. e.g. A
# response from the public body.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: incoming_message.rb,v 1.3 2007-10-30 14:13:46 francis Exp $

class IncomingMessage < ActiveRecord::Base
    belongs_to :info_request
    validates_presence_of :info_request

    validates_presence_of :raw_data

    # We store the raw email in the database, and parse it into 
    # a structured TMail every time we get it out again.
    def after_initialize
        @mail = TMail::Mail.parse(self.raw_data)
        @mail.base64_decode
    end

    # Return the structured TMail::Mail object
    # Documentation at http://i.loveruby.net/en/projects/tmail/doc/
    def mail
        @mail
    end

    # Return date mail was sent
    def sent_at
        # Use date it arrived (created_at) if mail itself doesn't have Date: header
        self.mail.date || self.created_at
    end
end


