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
# $Id: incoming_message.rb,v 1.14 2007-12-24 18:26:18 francis Exp $

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
    def self.remove_email_addresses(text)
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
    def self.remove_quoted_sections(text)
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
        # Find the body text 
        
        # XXX make this part scanning for mime parts properly recursive,
        # allow download of specific parts, and always show them all (in
        # case say the HTML differs from the text part)
        if self.mail.multipart?
            if self.mail.sub_type == 'alternative'
                # Choose best part from alternatives
                best_part = nil
                mail.parts.each do |m|
                    # Take the first one, or the last text/plain one
                    if not best_part
                        best_part = m
                    elsif m.content_type == 'text/plain'
                        best_part = m
                    end
                end
                text = best_part.body
            else
                # Just turn them all into text using built in
                text = self.mail.body
            end
        else
            text = self.mail.body
        end

        # Format the body text...
       
        # Show special emails we know about
        if not self.info_request.public_body.request_email.empty?
            text = text.gsub(self.info_request.public_body.request_email, "[" + self.info_request.public_body.short_name + " request email]")
        end
        if not self.info_request.public_body.complaint_email.empty?
            text = text.gsub(self.info_request.public_body.complaint_email, "[" + self.info_request.public_body.short_name + " complaint email]")
        end
        text = text.gsub(self.info_request.incoming_email, "[FOI #" + self.info_request.id.to_s + " email]")
        text = text.gsub(MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost'), "[GovernmentSpy contact email]")
        # Remove all other emails
        text = IncomingMessage.remove_email_addresses(text)

        # Removing quoted sections, adding HTML
        text = IncomingMessage.remove_quoted_sections(text)
        text = CGI.escapeHTML(text)
        text = MySociety::Format.make_clickable(text, :contract => 1)
        if collapse_quoted_sections
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


