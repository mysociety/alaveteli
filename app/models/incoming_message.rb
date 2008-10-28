# == Schema Information
# Schema version: 68
#
# Table name: incoming_messages
#
#  id                     :integer         not null, primary key
#  info_request_id        :integer         not null
#  created_at             :datetime        not null
#  updated_at             :datetime        not null
#  cached_attachment_text :text            
#  cached_main_body_text  :text            
#  raw_email_id           :integer         not null
#

# models/incoming_message.rb:
# An (email) message from really anybody to be logged with a request. e.g. A
# response from the public body.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: incoming_message.rb,v 1.157 2008-10-28 13:04:20 francis Exp $

# TODO
# Move some of the (e.g. quoting) functions here into rblib, as they feel
# general not specific to IncomingMessage.

require 'htmlentities'
require 'rexml/document'
require 'zip/zip'

module TMail
    class Mail
        attr_accessor :url_part_number
        attr_accessor :rfc822_attachment # when a whole email message is attached as text
        attr_accessor :within_rfc822_attachment # for parts within a message attached as text (for getting subject mainly)

        # Monkeypatch! (check to see if this becomes a standard function in
        # TMail::Mail, then use that, whatever it is called)
        def self.get_part_file_name(part)
            file_name = (part['content-location'] &&
                          part['content-location'].body) ||
                        part.sub_header("content-type", "name") ||
                        part.sub_header("content-disposition", "filename")
        end

        # Monkeypatch! :)
        # Returns the name of the person a message is from, or nil if there isn't
        # one or if there is only an email address.
        def safe_from
            if self.from and (not self.friendly_from.include?('@'))
                return self.friendly_from
            else 
                return nil
            end
        end

    end

    class Address
        # Monkeypatch!
        def Address.encode_quoted_string(text)
            if text.match(/[^A-Za-z0-9!#\$%&'*+\-\/=?^_`{|}~]/)
                # Contains characters which aren't valid in atoms, so make a
                # quoted-pair instead.
                text.gsub!(/(["\\])/, "\\\\\\1")
                text = '"' + text + '"'
            end
            return text
        end

        # Monkeypatch!
        def quoted_full
            if self.name
                Address.encode_quoted_string(self.name) + " <" + self.spec + ">"
            else
                self.spec
            end
        end
    end
end

# To add an image, create a file with appropriate name corresponding to the
# mime type in public/images e.g. icon_image_tiff_large.png
$file_extension_to_mime_type = {
    "txt" => 'text/plain',
    "pdf" => 'application/pdf',
    "rtf" => 'application/rtf',
    "doc" => 'application/vnd.ms-word',
    "docx" => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    "xls" => 'application/vnd.ms-excel',
    "xlsx" => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    "ppt" => 'application/vnd.ms-powerpoint',
    "pptx" => 'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    "tif" => 'image/tiff',
    "gif" => 'image/gif',
    "jpg" => 'image/jpeg', # XXX add jpeg
    "png" => 'image/png',
    "bmp" => 'image/bmp',
    "html" => 'text/html', # XXX add htm
    "vcf" => 'text/x-vcard',
    "zip" => 'application/zip',
    "delivery-status" => 'message/delivery-status'
}
# XXX doesn't have way of choosing default for inverse map - might want to add
# one when you need it
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
    attr_accessor :within_rfc822_subject # we use the subject as the filename for email attachments

    def display_filename
        if @filename 
            @filename
        else
            calc_ext = mimetype_to_extension(@content_type)
            if not calc_ext
                calc_ext = "bin"
            end

            if @within_rfc822_subject
                @within_rfc822_subject + "." + calc_ext
            else
                "attachment." + calc_ext
            end
        end
    end

    def display_size
        s = self.body.size

        if s > 1024 * 1024
            return  sprintf("%.1f", s.to_f / 1024 / 1024) + 'M'
        else
            return (s / 1024).to_s + 'K'
        end
    end

    def body_as_html
        tempfile = Tempfile.new('foiextract')
        tempfile.print body
        tempfile.flush

        if content_type == 'application/vnd.ms-word'
            # XXX do something with PNG files this spits out so they view too :)
            system("/usr/bin/wvHtml " + tempfile.path + " " + tempfile.path + ".html")
            html = File.read(tempfile.path + ".html")
            File.unlink(tempfile.path + ".html")
        elsif content_type == 'application/pdf'
            IO.popen("/usr/bin/pdftohtml -stdout -enc UTF-8 -noframes " + tempfile.path + "", "r") do |child|
                html = child.read() + "\n\n"
            end
        else
            raise "No HTML conversion available for type " + content_type
        end

        tempfile.close
        return html
    end

    def has_body_as_html?
        if content_type == 'application/vnd.ms-word'
            return true
        elsif content_type == 'application/pdf'
            return true
        end
        return false
    end
end

class IncomingMessage < ActiveRecord::Base
    belongs_to :info_request
    validates_presence_of :info_request

    validates_presence_of :raw_email

    has_many :outgoing_message_followups, :foreign_key => 'incoming_message_followup_id', :class_name => 'OutgoingMessage'

    has_many :info_request_events # never really has many, but could in theory

    belongs_to :raw_email

    # Return the structured TMail::Mail object
    # Documentation at http://i.loveruby.net/en/projects/tmail/doc/
    def mail
        if @mail.nil? && !self.raw_email.nil?
            # Hack round bug in TMail's MIME decoding. Example request which provokes it:
            # http://www.whatdotheyknow.com/request/reviews_of_unduly_lenient_senten#incoming-4830
            # Report of TMail bug:
            # http://rubyforge.org/tracker/index.php?func=detail&aid=21810&group_id=4512&atid=17370
            copy_of_raw_data = self.raw_email.data.gsub(/; boundary=\s+"/ims,'; boundary="') 

            @mail = TMail::Mail.parse(copy_of_raw_data)
            @mail.base64_decode
        end
        @mail
    end

    # Number the attachments in depth first tree order, for use in URLs.
    # XXX This fills in part.rfc822_attachment and part.url_part_number within
    # all the parts of the email (see TMail monkeypatch above for how these
    # attributes are added). ensure_parts_counted must be called before using
    # the attributes. This calculation is done only when required to avoid
    # having to load and parse the email unnecessarily.
    def after_initialize
        @parts_counted = false 
    end
    def ensure_parts_counted
        if not @parts_counted
            @count_parts_count = 0
            count_parts_recursive(self.mail)
            # we carry on using these numeric ids for attachments uudecoded from within text parts
            @count_first_uudecode_count = @count_parts_count
            @parts_counted = true
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
    # XXX relies on get_attachments_for_display calling ensure_parts_counted
    def self.get_attachment_by_url_part_number(attachments, found_url_part_number)
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
        if self.info_request.public_body.is_requestable?
            text = text.gsub(self.info_request.public_body.request_email, "[" + self.info_request.public_body.short_or_long_name + " request email]")
        end
        text = text.gsub(self.info_request.incoming_email, "[FOI #" + self.info_request.id.to_s + " email]")
        text = text.gsub(MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost'), "[WhatDoTheyKnow contact email]")
        return text
    end

    # Replaces all email addresses in (possibly binary data) with equal length alternative ones.
    # Also replaces censor items
    def binary_mask_stuff(text)
        orig_size = text.size

        # Replace ASCII email addresses...
        text.gsub!(MySociety::Validate.email_find_regexp) do |email| 
            email.gsub(/[^@.]/, 'x')
        end

        # And replace UCS-2 ones...
        # Find emails, by finding them in parts of text that have ASCII
        # equivalents to the UCS-2
        ascii_chars = text.gsub(/\0/, "")
        emails = ascii_chars.scan(MySociety::Validate.email_find_regexp)
        # Convert back to UCS-2, making a mask at the same time
        emails.map! {|email| [
                Iconv.conv('ucs-2', 'ascii', email[0]), 
                Iconv.conv('ucs-2', 'ascii', email[0].gsub(/[^@.]/, 'x'))
        ] }
        # Now search and replace the UCS-2 email with the UCS-2 mask
        for email, mask in emails
            text.gsub!(email, mask)
        end

        # Replace censor items
        text = self.info_request.apply_censor_rules_to_binary(text)

        raise "internal error in binary_mask_stuff" if text.size != orig_size
        return text
    end

    # Lotus notes quoting yeuch!
    def remove_lotus_quoting(text, replacement = "FOLDED_QUOTED_SECTION")
        text = text.dup
        name = self.info_request.user.name

        # To end of message sections
        # http://www.whatdotheyknow.com/request/university_investment_in_the_arm
        text.gsub!(/^#{name}[^\n]+\nSent by:[^\n]+\n.*/ims, "\n\n" + replacement)

        # Some other sort of forwarding quoting
        # http://www.whatdotheyknow.com/request/224/response/326
        text.gsub!(/^#{name}[^\n]+\n[0-9\/:\s]+\s+To\s+FOI requests at.*/ims, "\n\n" + replacement)

        # http://www.whatdotheyknow.com/request/how_do_the_pct_deal_with_retirin_33#incoming-930
        # http://www.whatdotheyknow.com/request/229/response/809
        text.gsub!(/^From: [^\n]+\nSent: [^\n]+\nTo:\s+['"?]#{name}['"]?\nSubject:.*/ims, "\n\n" + replacement)

        return text

    end

    # Remove emails, mobile phones and other details FOI officers ask us to remove.
    def remove_privacy_sensitive_things(text)
        text = text.dup

        # Remove any email addresses - we don't want bounce messages to leak out
        # either the requestor's email address or the request's response email
        # address out onto the internet
        text.gsub!(MySociety::Validate.email_find_regexp, "[email address]")

        # Mobile phone numbers
        # http://www.whatdotheyknow.com/request/failed_test_purchases_off_licenc#incoming-1013
        # http://www.whatdotheyknow.com/request/selective_licensing_statistics_i#incoming-550
        # http://www.whatdotheyknow.com/request/common_purpose_training_graduate#incoming-774
        text.gsub!(/(Mobile|Mob)([\s\/]*(Fax|Tel))*\s*:?[\s\d]*\d/, "[mobile number]")

        # Specific removals
        # http://www.whatdotheyknow.com/request/total_number_of_objects_in_the_n_6
        text.gsub!(/\*\*\*+\nPolly Tucker.*/ms, "")
        # http://www.whatdotheyknow.com/request/cctv_data_retention_and_use
        text.gsub!(/Andy 079.*/, "Andy [mobile number]")
        # http://www.whatdotheyknow.com/request/how_do_the_pct_deal_with_retirin_113
        text.gsub!(/(Complaints and Corporate Affairs Officer)\s+Westminster Primary Care Trust.+/ms, "\\1")

        # Remove WhatDoTheyKnow signup links
        text.gsub!(/http:\/\/www.whatdotheyknow.com\/c\/[^\s]+/, "[WDTK login link]")

        # Remove things from censor rules
        text = self.info_request.apply_censor_rules_to_text(text)

        return text
    end


    # Remove quoted sections from emails (eventually the aim would be for this
    # to do as good a job as GMail does) XXX bet it needs a proper parser
    # XXX and this FOLDED_QUOTED_SECTION stuff is a mess
    def self.remove_quoted_sections(text, replacement = "FOLDED_QUOTED_SECTION")
        text = text.dup
        replacement = "\n" + replacement + "\n"

        # First do this peculiar form of quoting, as the > single line quoting
        # further below messes with it. Note the carriage return where it wraps -
        # this can happen anywhere according to length of the name/email. e.g.
        # >>> D K Elwell <[email address]> 17/03/2008
        # 01:51:50 >>>
        # http://www.whatdotheyknow.com/request/71/response/108
        # http://www.whatdotheyknow.com/request/police_powers_to_inform_car_insu
        # http://www.whatdotheyknow.com/request/secured_convictions_aided_by_cct
        multiline_original_message = '(' + '''>>>.* \d\d/\d\d/\d\d\d\d\s+\d\d:\d\d(?::\d\d)?\s*>>>''' + ')'
        text.gsub!(/^(#{multiline_original_message}\n.*)$/ms, replacement)
 
        # Single line sections
        text.gsub!(/^(>.*\n)/, replacement)
        text.gsub!(/^(On .+ (wrote|said):\n)/, replacement)

        # Multiple line sections
        # http://www.whatdotheyknow.com/request/identity_card_scheme_expenditure
        # http://www.whatdotheyknow.com/request/parliament_protest_actions
        # http://www.whatdotheyknow.com/request/64/response/102
        # http://www.whatdotheyknow.com/request/47/response/283
        # http://www.whatdotheyknow.com/request/30/response/166
        # http://www.whatdotheyknow.com/request/52/response/238
        # http://www.whatdotheyknow.com/request/224/response/328 # example with * * * * *
        # http://www.whatdotheyknow.com/request/297/response/506
        ['-', '_', '*', '#'].each do |score|
            text.sub!(/(Disclaimer\s+)?  # appears just before
                        (
                            \s*(?:[#{score}]\s*){8,}\s*\n.*? # top line
                            (disclaimer:\n|confidential|received\sthis\semail\sin\serror|virus|intended\s+recipient|monitored\s+centrally|intended\s+(for\s+|only\s+for\s+use\s+by\s+)the\s+addressee|routinely\s+monitored|MessageLabs|unauthorised\s+use)
                            .*?((?:[#{score}]\s*){8,}\s*\n|\z) # bottom line OR end of whole string (for ones with no terminator XXX risky)
                        )
                       /imx, replacement)
        end

        # Special paragraphs
        # http://www.whatdotheyknow.com/request/identity_card_scheme_expenditure
        text.gsub!(/^[^\n]+Government\s+Secure\s+Intranet\s+virus\s+scanning
                    .*?
                    virus\sfree\.
                    /imx, replacement)
        text.gsub!(/^Communications\s+via\s+the\s+GSi\s+
                    .*?
                    legal\spurposes\.
                    /imx, replacement)
        # http://www.whatdotheyknow.com/request/net_promoter_value_scores_for_bb
        text.gsub!(/^http:\/\/www.bbc.co.uk
                    .*?
                    Further\s+communication\s+will\s+signify\s+your\s+consent\s+to\s+this\.
                    /imx, replacement)


        # To end of message sections
        # http://www.whatdotheyknow.com/request/123/response/192
        # http://www.whatdotheyknow.com/request/235/response/513
        # http://www.whatdotheyknow.com/request/445/response/743
        original_message = 
            '(' + '''----* This is a copy of the message, including all the headers. ----*''' + 
            '|' + '''----*\s*Original Message\s*----*''' +
            '|' + '''----*\s*Forwarded message.+----*''' +
            '|' + '''----*\s*Forwarded by.+----*''' +
            ')'
        # Could have a ^ at start here, but see messed up formatting here:
        # http://www.whatdotheyknow.com/request/refuse_and_recycling_collection#incoming-842
        text.gsub!(/(#{original_message}\n.*)$/mi, replacement)


        # Some silly Microsoft XML gets into parts marked as plain text.
        # e.g. http://www.whatdotheyknow.com/request/are_traffic_wardens_paid_commiss#incoming-401
        # Don't replace with "replacement" as it's pretty messy
        text.gsub!(/<\?xml:namespace[^>]*\/>/, " ")

        return text
    end

    # Flattens all the attachments, picking only one part where there are alternatives.
    # (This risks losing info if the unchosen alternative is the only one to contain 
    # useful info, but let's worry about that another time)
    def get_attachment_leaves
        return get_attachment_leaves_recursive(self.mail)
    end
    def get_attachment_leaves_recursive(curr_mail, within_rfc822_attachment = nil)
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
                leaves_found += get_attachment_leaves_recursive(best_part, within_rfc822_attachment)
            else
                # Add all parts
                curr_mail.parts.each do |m|
                    leaves_found += get_attachment_leaves_recursive(m, within_rfc822_attachment)
                end
            end
        else
            # Don't allow nil content_types
            if curr_mail.content_type.nil?
                curr_mail.content_type = 'application/octet-stream'
            end
            # PDFs often come with this mime type, fix it up for view code
            if curr_mail.content_type == 'application/octet-stream'
                calc_mime = filename_to_mimetype(TMail::Mail.get_part_file_name(curr_mail))
                if calc_mime
                    curr_mail.content_type = calc_mime
                end
            end 
            # e.g. http://www.whatdotheyknow.com/request/93/response/250
            if curr_mail.content_type == 'application/msexcel' or curr_mail.content_type == 'application/x-ms-excel'
                curr_mail.content_type = 'application/vnd.ms-excel'
            end
            if curr_mail.content_type == 'application/mspowerpoint' or curr_mail.content_type == 'application/x-ms-powerpoint'
                curr_mail.content_type = 'application/vnd.ms-powerpoint' 
            end
            if curr_mail.content_type == 'application/msword' or curr_mail.content_type == 'application/x-ms-word'
                curr_mail.content_type = 'application/vnd.ms-word'
            end
            if curr_mail.content_type == 'application/x-zip-compressed'
                curr_mail.content_type = 'application/zip'
            end
            # If the part is an attachment of email in text form
            if curr_mail.content_type == 'message/rfc822'
                ensure_parts_counted # fills in rfc822_attachment variable
                leaves_found += get_attachment_leaves_recursive(curr_mail.rfc822_attachment, curr_mail.rfc822_attachment)
            else
                # Store leaf
                curr_mail.within_rfc822_attachment = within_rfc822_attachment
                leaves_found += [curr_mail]
            end
        end
        return leaves_found
    end

    # Returns body text from main text part of email, converted to UTF-8, with uudecode removed
    def get_main_body_text
        # Cached as loading raw_email can be quite huge, and need this for just
        # search results
        if self.cached_main_body_text.nil?
            text = self.get_main_body_text_internal
            self.cached_main_body_text = text
            self.save!
        end
        text = self.cached_main_body_text

        # Strip the uudecode parts from main text
        text = text.split(/^begin.+^`\n^end\n/sm).join(" ")

        return text
    end
    # Returns body text from main text part of email, converted to UTF-8
    def get_main_body_text_internal
        main_part = get_main_body_text_part
        if main_part.nil?
            text = "[ Email has no body, please see attachments ]"
            text_charset = "utf-8"
        else
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
                text = HTMLEntities.decode_entities(text)
            end
        end

        # Charset conversion, turn everything into UTF-8
        if not text_charset.nil?
            begin
                # XXX specially convert unicode pound signs, was needed here
                # http://www.whatdotheyknow.com/request/88/response/352
                text.gsub!("£", Iconv.conv(text_charset, 'utf-8', '£')) 
                # Try proper conversion
                text = Iconv.conv('utf-8', text_charset, text)
            rescue Iconv::IllegalSequence, Iconv::InvalidEncoding
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
                    # Text looks like unlabelled nonsense, strip out anything that isn't UTF-8
                    text = Iconv.conv('utf-8//IGNORE', 'utf-8', text) + "\n\n[ WhatDoTheyKnow note: The above text was badly encoded, and has had strange characters removed. ]"
                end
            end

        end
        
        # An assertion that we have ended up with UTF-8 XXX can remove as this should
        # always be fine if code above is
        Iconv.conv('utf-8', 'utf-8', text)

        # Fix DOS style linefeeds to Unix style ones (or other later regexps won't work)
        # Needed for e.g. http://www.whatdotheyknow.com/request/60/response/98
        text = text.gsub(/\r\n/, "\n")

        return text
    end
    # Returns part which contains main body text, or nil if there isn't one
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
 
        # ... or if none, consider first part 
        p = leaves[0]
        # if it is a known type then don't use it, return no body (nil)
        if mimetype_to_extension(p.content_type)
            # this is guess of case where there are only attachments, no body text
            # e.g. http://www.whatdotheyknow.com/request/cost_benefit_analysis_for_real_n
            return nil
        end
        # otherwise return it assuming it is text (sometimes you get things
        # like binary/octet-stream, or the like, which are really text - XXX if
        # you find an example, put URL here - perhaps we should be always returning
        # nil in this case)
        return p
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
            attachment.filename = self.info_request.apply_censor_rules_to_text(uu.match(/^begin\s+[0-9]+\s+(.*)$/)[1])
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
        ensure_parts_counted

        main_part = get_main_body_text_part
        leaves = get_attachment_leaves
        attachments = []
        for leaf in leaves
            if leaf != main_part
                attachment = FOIAttachment.new
                attachment.body = leaf.body
                attachment.filename = self.info_request.apply_censor_rules_to_text(TMail::Mail.get_part_file_name(leaf))
                if leaf.within_rfc822_attachment
                    attachment.within_rfc822_subject = leaf.within_rfc822_attachment.subject

                    # XXX Could add subject / from to content here. But should
                    # only do for the first text part of the attached RFC822
                    # message.
                    #attachment.body = "Subject: " + CGI.escapeHTML(leaf.within_rfc822_attachment.subject) + "\n" + 
                    #    "From: " + CGI.escapeHTML(leaf.within_rfc822_attachment.safe_from) + "\n\n" + 
                    #    attachment.body
                end
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
        text = self.remove_privacy_sensitive_things(text)

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
            text = text.gsub(/FOLDED_QUOTED_SECTION/, "\n\n" + '<span class="unfold_link"><a href="?unfold=1#incoming-'+self.id.to_s+'">show quoted sections</a></span>' + "\n\n")
        else
            if folded_quoted_text.include?('FOLDED_QUOTED_SECTION')
                text = text + "\n\n" + '<span class="unfold_link"><a href="?#incoming-'+self.id.to_s+'">hide quoted sections</a></span>'
            end
        end
        text.strip!

        text = text.gsub(/\n/, '<br>')
        text = text.gsub(/(?:<br>\s*){2,}/, '<br><br>') # remove excess linebreaks that unnecessarily space it out
        return text
    end

    # Returns text of email for using in quoted section when replying
    def get_body_for_quoting
        # Find the body text and remove emails for privacy/anti-spam reasons
        text = get_main_body_text
        text = self.mask_special_emails(text)
        text = self.remove_privacy_sensitive_things(text)

        # Remove existing quoted sections
        text = self.remove_lotus_quoting(text, '')
        text = IncomingMessage.remove_quoted_sections(text, "")
    end

    # Returns text version of attachment text
    def get_attachment_text
        if self.cached_attachment_text.nil?
            attachment_text = self.get_attachment_text_internal
            self.cached_attachment_text = attachment_text
            self.save!
        end

        # Remove any privacy things
        text = self.cached_attachment_text
        text = self.mask_special_emails(text)
        text = self.remove_privacy_sensitive_things(text)
        return text
    end
    def IncomingMessage.get_attachment_text_internal_one_file(content_type, body)
        text = ''
        # XXX - tell all these command line tools to return utf-8
        if content_type == 'text/plain'
            text += body + "\n\n"
        else
            tempfile = Tempfile.new('foiextract')
            tempfile.print body
            tempfile.flush
            if content_type == 'application/vnd.ms-word'
                system("/usr/bin/wvText " + tempfile.path + " " + tempfile.path + ".txt")
                # Try catdoc if we get into trouble (e.g. for InfoRequestEvent 2701)
                if not File.exists?(tempfile.path + ".txt")
                    IO.popen("/usr/bin/catdoc " + tempfile.path, "r") do |child|
                        text += child.read() + "\n\n"
                    end
                else
                    text += File.read(tempfile.path + ".txt") + "\n\n"
                    File.unlink(tempfile.path + ".txt")
                end
            elsif content_type == 'application/rtf'
                IO.popen("/usr/bin/catdoc " + tempfile.path, "r") do |child|
                    text += child.read() + "\n\n"
                end
            elsif content_type == 'text/html'
                IO.popen("/usr/bin/lynx -force_html -dump " + tempfile.path, "r") do |child|
                    text += child.read() + "\n\n"
                end
            elsif content_type == 'application/vnd.ms-excel'
                # Bit crazy using strings - but xls2csv, xlhtml and py_xls2txt
                # only extract text from cells, not from floating notes. catdoc
                # may be fooled by weird character sets, but will probably do for
                # UK FOI requests.
                IO.popen("/usr/bin/strings " + tempfile.path, "r") do |child|
                    text += child.read() + "\n\n"
                end
            elsif content_type == 'application/vnd.ms-powerpoint'
                # ppthtml seems to catch more text, but only outputs HTML when
                # we want text, so just use catppt for now
                IO.popen("/usr/bin/catppt " + tempfile.path, "r") do |child|
                    text += child.read() + "\n\n"
                end
            elsif content_type == 'application/pdf'
                IO.popen("/usr/bin/pdftotext " + tempfile.path + " -", "r") do |child|
                    text += child.read() + "\n\n"
                end
            elsif content_type == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                # This is Microsoft's XML office document format.
                # Just pull out the main XML file, and strip it of text.
                xml = ''
                IO.popen("/usr/bin/unzip -qq -c " + tempfile.path + " word/document.xml", "r") do |child|
                    xml += child.read() + "\n\n"
                end
                doc = REXML::Document.new(xml)
                text += doc.each_element( './/text()' ){}.join(" ")
            elsif content_type == 'application/zip'
                # recurse into zip files
                zip_file = Zip::ZipFile.open(tempfile.path)
                for entry in zip_file
                    if entry.file?
                        filename = entry.to_s
                        body = entry.get_input_stream.read
                        calc_mime = filename_to_mimetype(filename)
                        if calc_mime
                            content_type = calc_mime
                        else
                            content_type = 'application/octet-stream'
                        end
                    
                        #STDERR.puts("doing file " + filename + " content type " + content_type)
                        text += IncomingMessage.get_attachment_text_internal_one_file(content_type, body)
                    end
                end
            end
            tempfile.close
        end

        return text
    end
    def get_attachment_text_internal
        # Extract text from each attachment
        text = ''
        attachments = self.get_attachments_for_display
        for attachment in attachments
            text += IncomingMessage.get_attachment_text_internal_one_file(attachment.content_type, attachment.body)
        end
        # Remove any bad characters
        text = Iconv.conv('utf-8//IGNORE', 'utf-8', text)
        return text
    end

    # Returns text for indexing
    def get_text_for_indexing
        return get_body_for_quoting + "\n\n" + get_attachment_text
    end

    # Returns the name of the person the incoming message is from, or nil if there isn't one
    # or if there is only an email address.
    def safe_mail_from
        return self.mail.safe_from
    end

    # Has message arrived "recently"?
    def recently_arrived
        (Time.now - self.created_at) <= 3.days
    end

    def fully_destroy
        ActiveRecord::Base.transaction do
            info_request_event = InfoRequestEvent.find_by_incoming_message_id(self.id)
            info_request_event.track_things_sent_emails.each { |a| a.destroy }
            info_request_event.user_info_request_sent_alerts.each { |a| a.destroy }
            info_request_event.destroy
            raw_email = self.raw_email
            self.destroy
            self.raw_email.destroy 
        end
    end

    # Search all info requests for 
    def IncomingMessage.find_all_unknown_mime_types
        for incoming_message in IncomingMessage.find(:all)
            for attachment in incoming_message.get_attachments_for_display
                raise "internal error incoming_message " + incoming_message.id.to_s if attachment.content_type.nil?
                if mimetype_to_extension(attachment.content_type).nil?
                    STDERR.puts "Unknown type for /request/" + incoming_message.info_request.id.to_s + "#incoming-"+incoming_message.id.to_s
                    STDERR.puts " " + attachment.filename.to_s + " " + attachment.content_type.to_s
                end
            end
        end

        return nil
    end

    # Returns space separated list of file extensions of attachments to this message. Defaults to
    # the normal extension for known mime type, otherwise uses other extensions.
    def get_present_file_extensions
        ret = {}
        for attachment in self.get_attachments_for_display
            ext = mimetype_to_extension(attachment.content_type)
            ext = File.extname(attachment.filename).gsub(/^[.]/, "") if ext.nil? && !attachment.filename.nil?
            ret[ext] = 1 if !ext.nil?
        end
        return ret.keys.join(" ")
    end
    # Return space separated list of all file extensions known
    def IncomingMessage.get_all_file_extentions
        return $file_extension_to_mime_type.keys.join(" ")
    end

    # Return false if for some reason this is a message that we should let them reply to
    def valid_to_reply_to?
        # check validity of email
        email = self.mail.from_addrs[0].spec
        if !MySociety::Validate.is_valid_email(email)
            return false
        end

        # reject postmaster - authorities seem to nearly always not respond to
        # email to postmaster, and it tells to only happen after delivery failure.
        prefix = email
        prefix =~ /^(.*)@/
        prefix = $1
        if !prefix.nil? && prefix == 'postmaster'
            return false
        end

        return true
    end
end


