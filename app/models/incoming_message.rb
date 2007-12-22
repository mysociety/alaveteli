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
# $Id: incoming_message.rb,v 1.9 2007-12-22 03:04:27 francis Exp $

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

    # Remove email addresses from text (mainly to reduce spam - particularly
    # we want to stop spam to our own magic archiving request-* addresses,
    # which would otherwise appear a lot in bounce messages and reply quotes etc.)
    def self.email_filter(text)
        text = text.dup

        # Remove any email addresses - we don't want bounce messages to leak out
        # either the requestor's email address or the request's response email
        # address out onto the internet
        rx = Regexp.new(MySociety::Validate.email_match_regexp)
        text.gsub!(rx, "...@...")

        return text
    end

    # Remove quoted sections from emails (eventually the aim would be for this
    # to do as good a job as GMail does) XXX bet it needs a proper parser
    # XXX and this BEGIN_QUOTED / END_QUOTED stuff is a mess
    def self.remove_email_quotage(text)
        text = text.dup
        
        text.gsub!(/^(>.+\n)/, "BEGIN_QUOTED\\1END_QUOTED")
        text.gsub!(/^(On .+ wrote:\n)/, "BEGIN_QUOTED\\1END_QUOTED")

        original_message = 
            '(' + '''------ This is a copy of the message, including all the headers. ------''' + 
            '|' + '''-----Original Message-----''' +
            ')'

        text.gsub!(/^(#{original_message}\n.*)$/m, "BEGIN_QUOTED\\1END_QUOTED")

        return text
    end

    # Returns body text as HTML with quotes flattened, and emails removed.
    def get_body_for_display(collapse_quoted_sections = true)
        parts = self.mail.parts
        if parts.size > 0
            #return self.mail.parts[0].class.to_s
            text = self.mail.body
        else
            text = self.mail.quoted_body
        end

        text = IncomingMessage.email_filter(text)
        text = IncomingMessage.remove_email_quotage(text)
        text = CGI.escapeHTML(text)
        if collapse_quoted_sections
            #text = text.gsub(/BEGIN_QUOTED/, '<span class="quoted_email">')
            #text = text.gsub(/END_QUOTED/, '</span>')
            text = text.gsub(/(BEGIN_QUOTED(.+?)END_QUOTED)+/m, '<a href="?unfold=1">show quoted sections</a>')
        else
            if text.include?('BEGIN_QUOTED')
                text = text.gsub(/BEGIN_QUOTED(.+?)END_QUOTED/m, '\1')
                text = text + '<a href="?">hide quoted sections</a>'
            end
        end
        text = text.gsub(/\n/, '<br>')

        return text
    end

end


