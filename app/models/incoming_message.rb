# == Schema Information
# Schema version: 25
#
# Table name: incoming_messages
#
#  id                   :integer         not null, primary key
#  info_request_id      :integer         
#  raw_data             :text            
#  created_at           :datetime        
#  updated_at           :datetime        
#  user_classified      :boolean         default(false)
#  contains_information :boolean         
#  is_bounce            :boolean         default(false)
#

# models/incoming_message.rb:
# An (email) message from really anybody to be logged with a request. e.g. A
# response from the public body.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: incoming_message.rb,v 1.34 2008-01-22 19:45:07 francis Exp $


# TODO
# Move some of the (e.g. quoting) functions here into rblib, as they feel
# general not specific to IncomingMessage.

module TMail
    class Mail
        attr_accessor :url_part_number

        def self.get_part_file_name(part)
            file_name = (part['content-location'] &&
                          part['content-location'].body) ||
                        part.sub_header("content-type", "name") ||
                        part.sub_header("content-disposition", "filename")
        end
    end
end

class IncomingMessage < ActiveRecord::Base
    belongs_to :info_request
    validates_presence_of :info_request

    validates_presence_of :raw_data

    has_many :rejection_reasons

    has_many :outgoing_message_followups, :class_name => OutgoingMessage

    # Return the structured TMail::Mail object
    # Documentation at http://i.loveruby.net/en/projects/tmail/doc/
    def mail
        if @mail.nil? && !self.raw_data.nil?
            @mail = TMail::Mail.parse(self.raw_data)
            @mail.base64_decode
        end
        @mail
    end

    # Number the attachments in depth first tree order, for use in URLs.
    def after_initialize
        if !self.mail.nil?
            @count_parts_count = 0
            count_parts_recursive(self.mail)
        end
    end
    def count_parts_recursive(part)
        if part.multipart?
            part.parts.each do |p|
                count_parts_recursive(p)
            end
        else
            @count_parts_count += 1
            part.url_part_number = @count_parts_count
        end
    end
    # And look up by URL part number to get an attachment
    def self.get_attachment_by_url_part_number(attachments, found_url_part_number)
        @count_parts_count = 0  
        attachments.each do |a|
            if a.url_part_number == found_url_part_number
                return a
            end
        end
        return nil
    end

    # Return date mail was sent
    def sent_at
        # Use date it arrived (created_at) if mail itself doesn't have Date: header
        self.mail.date || self.created_at
    end

    # Converts email addresses we know about into textual descriptions of them
    def mask_special_emails(text)
        # XXX can later display some of these special emails as actual emails,
        # if they are public anyway.  For now just be precautionary and only
        # put in descriptions of them in square brackets.
        if not self.info_request.public_body.request_email.empty?
            text = text.gsub(self.info_request.public_body.request_email, "[" + self.info_request.public_body.short_name + " request email]")
        end
        if not self.info_request.public_body.complaint_email.empty?
            text = text.gsub(self.info_request.public_body.complaint_email, "[" + self.info_request.public_body.short_name + " complaint email]")
        end
        text = text.gsub(self.info_request.incoming_email, "[FOI #" + self.info_request.id.to_s + " email]")
        text = text.gsub(self.info_request.envelope_email, "[FOI #" + self.info_request.id.to_s + " bounce email]")
        text = text.gsub(MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost'), "[GovernmentSpy contact email]")
        return text
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
    # XXX and this FOLDED_QUOTED_SECTION stuff is a mess
    def self.remove_quoted_sections(text, replacement = "FOLDED_QUOTED_SECTION")
        text = text.dup
        
        # Single line sections
        text.gsub!(/^(>.*\n)/, replacement)
        text.gsub!(/^(On .+ (wrote|said):\n)/, replacement)

        # Multiple line sections
        ['-', '_'].each do |score|
            text.gsub!(/(\s*#{score}{20,}\n.*?disclaimer:\n.*?#{score}{20,}\n)/im, "\n\n" + replacement)
        end

        # To end of message sections
        original_message = 
            '(' + '''------ This is a copy of the message, including all the headers. ------''' + 
            '|' + '''-----Original Message-----''' +
            ')'
        text.gsub!(/^(#{original_message}\n.*)$/m, replacement)

        return text
    end

    # Flattens all the attachments, picking only one part where there are alternatives.
    # (This risks losing info if the unchosen alternative is the only one to contain 
    # useful info, but let's worry about that another time)
    def get_attachment_leaves
        return get_attachment_leaves_recursive(self.mail, [])
    end
    def get_attachment_leaves_recursive(curr_mail, leaves_so_far)
        if curr_mail.multipart?
            if curr_mail.sub_type == 'alternative'
                # Choose best part from alternatives
                best_part = nil
                self.mail.parts.each do |m|
                    # Take the first one, or the last text/plain one
                    # XXX - could do better!
                    if not best_part
                        best_part = m
                    elsif m.content_type == 'text/plain'
                        best_part = m
                    end
                end
                leaves_so_far += get_attachment_leaves_recursive(best_part, [])
            else
                # Add all parts
                curr_mail.parts.each do |m|
                    leaves_so_far += get_attachment_leaves_recursive(m, [])
                end
            end
        else
            leaves_so_far += [curr_mail]
        end
        return leaves_so_far
    end

    # Returns body text from main text part of email, converted to UTF-8
    def get_main_body_text
        main_part = get_main_body_text_part
        text = main_part.body
        text_charset = main_part.charset

        # Charset conversion, turn everything into UTF-8
        if not text_charset.nil?
            if text_charset == 'us-ascii'
                # Emails say US ASCII, but mean Windows-1252
                # XXX How do we autodetect this properly?
                text = Iconv.conv('utf-8', 'windows-1252', text)
            end
        end

        return text
    end
    # Returns part which contains main body text
    def get_main_body_text_part
        leaves = get_attachment_leaves
        
        # Find first part which is text
        leaves.each do |p|
            # XXX do we need to look at content-disposition? I'm guessing not *really*.
            #(part['content-disposition'] && part['content-disposition'].disposition == "attachment") ||
            if p.main_type == 'text'
                return p
            end
        end
        # ... or if none, just first part (covers cases of one part, not
        # labelled as text - not sure # what the better way to handle this is)
        return leaves[0]
    end

    # Returns all attachments for use in display code
    def get_attachments_for_display
        main_part = get_main_body_text_part
        leaves = get_attachment_leaves
        leaves = leaves.select do |p|
            p != main_part
        end
        return leaves
    end

    # Returns body text as HTML with quotes flattened, and emails removed.
    def get_body_for_html_display(collapse_quoted_sections = true)
        # Find the body text and remove emails for privacy/anti-spam reasons
        text = get_main_body_text
        text = self.mask_special_emails(text)
        text = IncomingMessage.remove_email_addresses(text)

        # Remove quoted sections, adding HTML. XXX The FOLDED_QUOTED_SECTION is
        # a nasty hack so we can escape other HTML before adding the unfold
        # links, without escaping them. Rather than using some proper parser
        # making a tree structure (I don't know of one that is to hand, that
        # works well in this kind of situation, such as with regexps).
        folded_quoted_text = IncomingMessage.remove_quoted_sections(text, 'FOLDED_QUOTED_SECTION')
        if collapse_quoted_sections
            text = folded_quoted_text
        end
        text = CGI.escapeHTML(text)
        text = MySociety::Format.make_clickable(text, :contract => 1)
        if collapse_quoted_sections
            text = text.gsub(/(\s*FOLDED_QUOTED_SECTION\s*)+/m, "\n\n" + '<span class="unfold_link"><a href="?unfold=1">show quoted sections</a></span>' + "\n")
        else
            if folded_quoted_text.include?('FOLDED_QUOTED_SECTION')
                text = text + "\n\n" + '<span class="unfold_link"><a href="?">hide quoted sections</a></span>'
            end
        end
        text = text.gsub(/\n/, '<br>')

        return text
    end

    # Returns text of email for using in quoted section when replying
    def get_body_for_quoting
        # Find the body text and remove emails for privacy/anti-spam reasons
        text = get_main_body_text
        text = self.mask_special_emails(text)
        text = IncomingMessage.remove_email_addresses(text)

        # Remove existing quoted sections
        text = IncomingMessage.remove_quoted_sections(text, "")
    end

    # Returns the name of the person the incoming message is from, or nil if there isn't one
    # or if there is only an email address.
    def safe_mail_from
        if self.mail.from and (not self.mail.friendly_from.include?('@'))
            return self.mail.friendly_from
        else 
            return nil
        end
    end
end


