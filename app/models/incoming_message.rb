# == Schema Information
# Schema version: 51
#
# Table name: incoming_messages
#
#  id              :integer         not null, primary key
#  info_request_id :integer         not null
#  raw_data        :text            not null
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#

# models/incoming_message.rb:
# An (email) message from really anybody to be logged with a request. e.g. A
# response from the public body.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: incoming_message.rb,v 1.83 2008-04-21 14:45:06 francis Exp $

# TODO
# Move some of the (e.g. quoting) functions here into rblib, as they feel
# general not specific to IncomingMessage.

module TMail
    class Mail
        attr_accessor :url_part_number
        attr_accessor :rfc822_attachment # when a whole email message is attached as text

        # Monkeypatch! (check to see if this becomes a standard function in
        # TMail::Mail, then use that, whatever it is called)
        def self.get_part_file_name(part)
            file_name = (part['content-location'] &&
                          part['content-location'].body) ||
                        part.sub_header("content-type", "name") ||
                        part.sub_header("content-disposition", "filename")
        end
    end
end

# To add an image, create a file with appropriate name corresponding to the
# mime type in public/images e.g. icon_application_msexcel_large.png
$file_extension_to_mime_type = {
    "txt" => 'text/plain',
    "pdf" => 'application/pdf',
    "doc" => 'application/msword',
    "rtf" => 'application/rtf',
    "xls" => 'application/msexcel',
    "tif" => 'image/tiff',
    "gif" => 'image/gif'
}
$file_extension_to_mime_type_rev = $file_extension_to_mime_type.invert

# XXX clearly this shouldn't be a global function, or the above global vars.
def filename_to_mimetype(filename)
    if not filename
        return nil
    end
    if filename.match(/\.([^.]+)$/i)
        lext = $1.downcase
        if $file_extension_to_mime_type.include?(lext)
            return $file_extension_to_mime_type[lext]
        end
    end
    return nil
end

def mimetype_to_extension(mime)
    if $file_extension_to_mime_type_rev.include?(mime)
        return $file_extension_to_mime_type_rev[mime]
    end
    return nil
end
 
# This is the type which is used to send data about attachments to the view
class FOIAttachment
    attr_accessor :body
    attr_accessor :content_type
    attr_accessor :filename
    attr_accessor :url_part_number

    def display_filename
        if @filename 
            @filename
        else
            calc_ext = mimetype_to_extension(@content_type)
            if calc_ext
                "attachment." + calc_ext
            else
                "attachment.bin"
            end
        end
    end
end

class IncomingMessage < ActiveRecord::Base
    belongs_to :info_request
    validates_presence_of :info_request

    validates_presence_of :raw_data

    has_many :outgoing_message_followups, :foreign_key => 'incoming_message_followup_id', :class_name => 'OutgoingMessage'

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
            # we carry on using these numeric ids for attachments uudecoded from within text parts
            @count_first_uudecode_count = @count_parts_count
        end
    end
    def count_parts_recursive(part)
        if part.multipart?
            part.parts.each do |p|
                count_parts_recursive(p)
            end
        else
            if part.content_type == 'message/rfc822'
                # An email attached as text
                # e.g. http://www.whatdotheyknow.com/request/64/response/102
                part.rfc822_attachment = TMail::Mail.parse(part.body)
                count_parts_recursive(part.rfc822_attachment)
            else
                @count_parts_count += 1
                part.url_part_number = @count_parts_count
            end
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
            text = text.gsub(self.info_request.public_body.request_email, "[" + self.info_request.public_body.short_or_long_name + " request email]")
        end
        text = text.gsub(self.info_request.incoming_email, "[FOI #" + self.info_request.id.to_s + " email]")
        text = text.gsub(MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost'), "[WhatDoTheyKnow contact email]")
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
        rx = Regexp.new("(\\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}\\b)")
        text.gsub!(rx, "[email address]")

        return text
    end

    # Lotus notes quoting yeuch!
    def remove_lotus_quoting(text, replacement = "FOLDED_QUOTED_SECTION")
        text = text.dup
        name = self.info_request.user.name

        # To end of message sections
        # http://www.whatdotheyknow.com/request/university_investment_in_the_arm
        text.gsub!(/^#{name}[^\n]+\nSent by:[^\n]+\n.*/ims, "\n\n" + replacement)

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
        # http://www.whatdotheyknow.com/request/identity_card_scheme_expenditure
        # http://www.whatdotheyknow.com/request/parliament_protest_actions
        # http://www.whatdotheyknow.com/request/64/response/102
        ['-', '_', '*'].each do |score|
            text.gsub!(/(Disclaimer\s+)?  # appears just before
                        (\s*[#{score}]{20,}\n.*? # top line ------------
                        (disclaimer:\n|confidential|received\sthis\semail\sin\serror|scanned\sfor\sviruses)
                        .*?[#{score}]{20,}\n) # bottom line -----------
                       /imx, "\n\n" + replacement)
        end

        # Special paragraphs
        # http://www.whatdotheyknow.com/request/identity_card_scheme_expenditure
        text.gsub!(/^[^\n]+Government\s+Secure\s+Intranet\s+virus\s+scanning
                    .*?
                    virus\sfree\.
                    /imx, "\n\n" + replacement)
        text.gsub!(/^Communications\s+via\s+the\s+GSi\s+
                    .*?
                    legal\spurposes\.
                    /imx, "\n\n" + replacement)
        # http://www.whatdotheyknow.com/request/net_promoter_value_scores_for_bb
        text.gsub!(/^http:\/\/www.bbc.co.uk
                    .*?
                    Further\s+communication\s+will\s+signify\s+your\s+consent\s+to\s+this\.
                    /imx, "\n\n" + replacement)


        # To end of message sections
        original_message = 
            '(' + '''------ This is a copy of the message, including all the headers. ------''' + 
            '|' + '''-----*\s*Original Message\s*-----*''' +
            '|' + '''-----*\s*Forwarded message.+-----*''' +
            ')'
        text.gsub!(/^(#{original_message}\n.*)$/m, replacement)

        return text
    end

    # Flattens all the attachments, picking only one part where there are alternatives.
    # (This risks losing info if the unchosen alternative is the only one to contain 
    # useful info, but let's worry about that another time)
    def get_attachment_leaves
        return get_attachment_leaves_recursive(self.mail)
    end
    def get_attachment_leaves_recursive(curr_mail)
        leaves_found = []
        if curr_mail.multipart?
            if curr_mail.sub_type == 'alternative'
                # Choose best part from alternatives
                best_part = nil
                curr_mail.parts.each do |m|
                    # Take the first one, or the last text/plain one
                    # XXX - could do better!
                    if not best_part
                        best_part = m
                    elsif m.content_type == 'text/plain'
                        best_part = m
                    end
                end
                leaves_found += get_attachment_leaves_recursive(best_part)
            else
                # Add all parts
                curr_mail.parts.each do |m|
                    leaves_found += get_attachment_leaves_recursive(m)
                end
            end
        else
            # PDFs often come with this mime type, fix it up for view code
            if curr_mail.content_type == 'application/octet-stream'
                calc_mime = filename_to_mimetype(TMail::Mail.get_part_file_name(curr_mail))
                if calc_mime
                    curr_mail.content_type = calc_mime
                end
            end 
            # e.g. http://www.whatdotheyknow.com/request/93/response/250
            if curr_mail.content_type == 'application/vnd.ms-excel'
                curr_mail.content_type = 'application/msexcel'
            end
            if curr_mail.content_type == 'application/vnd.ms-word'
                curr_mail.content_type = 'application/msword'
            end
            # If the part is an attachment of email in text form
            if curr_mail.content_type == 'message/rfc822'
                # This has been expanded from text to an email in count_parts_recursive above
                leaves_found += get_attachment_leaves_recursive(curr_mail.rfc822_attachment)
            else
                # Store leaf
                leaves_found += [curr_mail]
            end
        end
        return leaves_found
    end

    # Returns body text from main text part of email, converted to UTF-8, with uudecode removed
    def get_main_body_text
        text = get_main_body_text_internal

        # Strip the uudecode parts from main text
        text = text.split(/^begin.+^`\n^end\n/sm).join(" ")

        return text
    end
    # Returns body text from main text part of email, converted to UTF-8
    def get_main_body_text_internal
        main_part = get_main_body_text_part
        text = main_part.body
        text_charset = main_part.charset
        if main_part.content_type == 'text/html'
            # XXX could use better HTML to text conversion than this!
            # (it only matters for emails without a text part, so not a massive deal
            # e.g. http://www.whatdotheyknow.com/request/35/response/177 )
            text.gsub!(/<br[^>]+>/, "\n")
            text.gsub!(/<p[^>]+>/, "\n\n")
            text.gsub!(/<div[^>]+>/, "\n\n")
            text.gsub!(/<\/?[^>]*>/, "")
        end

        # Charset conversion, turn everything into UTF-8
        if not text_charset.nil?
            begin
                text = Iconv.conv('utf-8', text_charset, text)
            rescue Iconv::IllegalSequence
                # Clearly specified charset was nonsense
                text_charset = nil
            end
        end
        if text_charset.nil?
            # No specified charset, so guess
            
            # Could use rchardet here, but it had trouble with 
            #   http://www.whatdotheyknow.com/request/107/response/144
            # So I gave up - most likely in UK we'll only get windows-1252 anyway.

            begin
                # See if it is good UTF-8 anyway
                text = Iconv.conv('utf-8', 'utf-8', text)
            rescue Iconv::IllegalSequence
                begin
                    # Or is it good windows-1252, most likely
                    text = Iconv.conv('utf-8', 'windows-1252', text)
                rescue Iconv::IllegalSequence
                    # Just use it even though it is nonsense - treat as UTF-8
                end
            end

        end

        # Fix DOS style linefeeds to Unix style ones (or other later regexps won't work)
        # Needed for e.g. http://www.whatdotheyknow.com/request/60/response/98
        text = text.gsub(/\r\n/, "\n")

        return text
    end
    # Returns part which contains main body text
    def get_main_body_text_part
        leaves = get_attachment_leaves
        
        # Find first part which is text/plain
        leaves.each do |p|
            if p.content_type == 'text/plain'
                return p
            end
        end

        # Otherwise first part which is any sort of text
        leaves.each do |p|
            if p.main_type == 'text'
                return p
            end
        end
 
        # ... or if none, just first part (covers cases of one part, not
        # labelled as text - not sure what the better way to handle this is)
        return leaves[0]
    end
    # Returns attachments that are uuencoded in main body part
    def get_main_body_text_uudecode_attachments
        text = get_main_body_text_internal

        # Find any uudecoded things buried in it, yeuchly
        uus = text.scan(/^begin.+^`\n^end\n/sm)
        attachments = []
        for uu in uus
            # Decode the string
            content = nil
            tempfile = Tempfile.new('foiuu')
            tempfile.print uu
            tempfile.flush
            IO.popen("/usr/bin/uudecode " + tempfile.path + " -o -", "r") do |child|
                content = child.read()
            end
            tempfile.close
            # Make attachment type from it, working out filename and mime type
            attachment = FOIAttachment.new()
            attachment.body = content
            attachment.filename = uu.match(/^begin\s+[0-9]+\s+(.*)$/)[1]
            calc_mime = filename_to_mimetype(attachment.filename)
            if calc_mime
                attachment.content_type = calc_mime
            else
                attachment.content_type = 'application/octet-stream'
            end
            attachments += [attachment]
        end
        
        return attachments
    end

    # Returns all attachments for use in display code
    def get_attachments_for_display
        main_part = get_main_body_text_part
        leaves = get_attachment_leaves
        attachments = []
        for leaf in leaves
            if leaf != main_part
                attachment = FOIAttachment.new
                attachment.body = leaf.body
                attachment.filename = TMail::Mail.get_part_file_name(leaf) 
                attachment.content_type = leaf.content_type
                attachment.url_part_number = leaf.url_part_number
                attachments += [attachment]
            end
        end

        uudecode_attachments = get_main_body_text_uudecode_attachments
        c = @count_first_uudecode_count
        for uudecode_attachment in uudecode_attachments
            c += 1
            uudecode_attachment.url_part_number = c
            attachments += [uudecode_attachment]
        end

        return attachments
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
        folded_quoted_text = self.remove_lotus_quoting(text, 'FOLDED_QUOTED_SECTION')
        folded_quoted_text = IncomingMessage.remove_quoted_sections(folded_quoted_text, 'FOLDED_QUOTED_SECTION')
        if collapse_quoted_sections
            text = folded_quoted_text
        end
        text = MySociety::Format.simplify_angle_bracketed_urls(text)
        text = CGI.escapeHTML(text)
        text = MySociety::Format.make_clickable(text, :contract => 1)
        if collapse_quoted_sections
            text = text.gsub(/(\s*FOLDED_QUOTED_SECTION\s*)+/m, "FOLDED_QUOTED_SECTION")
            text.strip!
            # if there is nothing but quoted stuff, then show the subject
            if text == "FOLDED_QUOTED_SECTION"
                text = "[Subject only] " + CGI.escapeHTML(self.mail.subject) + text
            end
            # and display link for quoted stuff
            text = text.gsub(/FOLDED_QUOTED_SECTION/, "\n\n" + '<span class="unfold_link"><a href="?unfold=1">show quoted sections</a></span>' + "\n")
        else
            if folded_quoted_text.include?('FOLDED_QUOTED_SECTION')
                text = text + "\n\n" + '<span class="unfold_link"><a href="?">hide quoted sections</a></span>'
            end
        end
        text.strip!

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

    # Returns text version of attachment text
    def get_attachment_text
        text = ''
        attachments = self.get_attachments_for_display
        for attachment in attachments
            if attachment.content_type == 'text/plain'
                text += attachment.body + "\n\n"
            else
                tempfile = Tempfile.new('foiextract')
                tempfile.print attachment.body
                tempfile.flush
                if attachment.content_type == 'application/msword'
                    system("/usr/bin/wvText " + tempfile.path + " " + tempfile.path + ".txt")
                    text += File.read(tempfile.path + ".txt") + "\n\n"
                    File.unlink(tempfile.path + ".txt")
                elsif attachment.content_type == 'application/rtf'
                    IO.popen("/usr/bin/catdoc " + tempfile.path, "r") do |child|
                        text += child.read() + "\n\n"
                    end
                elsif attachment.content_type == 'application/msexcel'
                    # Bit crazy using strings - but xls2csv, xlhtml and py_xls2txt
                    # only extract text from cells, not from floating notes. catdoc
                    # may be fooled by weird character sets, but will probably do for
                    # UK FOI requests.
                    IO.popen("/usr/bin/strings " + tempfile.path, "r") do |child|
                        text += child.read() + "\n\n"
                    end
                elsif attachment.content_type == 'application/pdf'
                    IO.popen("/usr/bin/pdftotext " + tempfile.path + " -", "r") do |child|
                        text += child.read() + "\n\n"
                    end
                end
                tempfile.close
            end
        end
        return text
    end

    # Returns text for indexing
    def get_text_for_indexing
        return get_body_for_quoting + "\n\n" + get_attachment_text
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

    # Has message arrived "recently"?
    def recently_arrived
        (Time.now - self.created_at) <= 3.days
    end
end


