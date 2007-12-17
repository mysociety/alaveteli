# == Schema Information
# Schema version: 21
#
# Table name: incoming_messages
#
#  id                   :integer         not null, primary key
#  info_request_id      :integer         
#  raw_data             :text            
#  created_at           :datetime        
#  updated_at           :datetime        
#  user_classified      :boolean         
#  contains_information :boolean         
#

# models/incoming_message.rb:
# An (email) message from really anybody to be logged with a request. e.g. A
# response from the public body.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: incoming_message.rb,v 1.7 2007-12-17 19:35:13 francis Exp $

class IncomingMessage < ActiveRecord::Base
    belongs_to :info_request
    validates_presence_of :info_request

    validates_presence_of :raw_data

    has_many :rejection_reasons

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

    # Use this when displaying the body text
    def sanitised_body
        body = self.mail.body.dup

        # Remove any email addresses - we don't want bounce messages to leak out
        # either the requestor's email address or the request's response email
        # address out onto the internet
        rx = Regexp.new(MySociety::Validate.email_match_regexp)
        body.gsub!(rx, "...@...")

        return body
    end
end


