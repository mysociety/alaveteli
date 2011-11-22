# encoding: UTF-8

# == Schema Information
# Schema version: 95
#
# Table name: incoming_messages
#
#  id                             :integer         not null, primary key
#  info_request_id                :integer         not null
#  created_at                     :datetime        not null
#  updated_at                     :datetime        not null
#  raw_email_id                   :integer         not null
#  cached_attachment_text_clipped :text            
#  cached_main_body_text_folded   :text            
#  cached_main_body_text_unfolded :text            
#

# models/incoming_message.rb:
# An (email) message from really anybody to be logged with a request. e.g. A
# response from the public body.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: incoming_message.rb,v 1.228 2009-10-21 11:24:14 francis Exp $

# TODO
# Move some of the (e.g. quoting) functions here into rblib, as they feel
# general not specific to IncomingMessage.

require 'alaveteli_file_types'
require 'htmlentities'
require 'rexml/document'
require 'zip/zip'
require 'mapi/msg'
require 'mapi/convert'

# Monkeypatch! Adding some extra members to store extra info in.
module TMail
    class Mail
        attr_accessor :url_part_number
        attr_accessor :rfc822_attachment # when a whole email message is attached as text
        attr_accessor :within_rfc822_attachment # for parts within a message attached as text (for getting subject mainly)
    end
end

# This is the type which is used to send data about attachments to the view
class FOIAttachment
    attr_accessor :body
    attr_accessor :content_type
    attr_accessor :filename
    attr_accessor :url_part_number
    attr_accessor :within_rfc822_subject # we use the subject as the filename for email attachments

    # List of DSN codes taken from RFC 3463
    # http://tools.ietf.org/html/rfc3463
    DsnToMessage = {
         'X.1.0' => 'Other address status',
         'X.1.1' => 'Bad destination mailbox address',
         'X.1.2' => 'Bad destination system address',
         'X.1.3' => 'Bad destination mailbox address syntax',
         'X.1.4' => 'Destination mailbox address ambiguous',
         'X.1.5' => 'Destination mailbox address valid',
         'X.1.6' => 'Mailbox has moved',
         'X.1.7' => 'Bad sender\'s mailbox address syntax',
         'X.1.8' => 'Bad sender\'s system address',
         'X.2.0' => 'Other or undefined mailbox status',
         'X.2.1' => 'Mailbox disabled, not accepting messages',
         'X.2.2' => 'Mailbox full',
         'X.2.3' => 'Message length exceeds administrative limit.',
         'X.2.4' => 'Mailing list expansion problem',
         'X.3.0' => 'Other or undefined mail system status',
         'X.3.1' => 'Mail system full',
         'X.3.2' => 'System not accepting network messages',
         'X.3.3' => 'System not capable of selected features',
         'X.3.4' => 'Message too big for system',
         'X.4.0' => 'Other or undefined network or routing status',
         'X.4.1' => 'No answer from host',
         'X.4.2' => 'Bad connection',
         'X.4.3' => 'Routing server failure',
         'X.4.4' => 'Unable to route',
         'X.4.5' => 'Network congestion',
         'X.4.6' => 'Routing loop detected',
         'X.4.7' => 'Delivery time expired',
         'X.5.0' => 'Other or undefined protocol status',
         'X.5.1' => 'Invalid command',
         'X.5.2' => 'Syntax error',
         'X.5.3' => 'Too many recipients',
         'X.5.4' => 'Invalid command arguments',
         'X.5.5' => 'Wrong protocol version',
         'X.6.0' => 'Other or undefined media error',
         'X.6.1' => 'Media not supported',
         'X.6.2' => 'Conversion required and prohibited',
         'X.6.3' => 'Conversion required but not supported',
         'X.6.4' => 'Conversion with loss performed',
         'X.6.5' => 'Conversion failed',
         'X.7.0' => 'Other or undefined security status',
         'X.7.1' => 'Delivery not authorized, message refused',
         'X.7.2' => 'Mailing list expansion prohibited',
         'X.7.3' => 'Security conversion required but not possible',
         'X.7.4' => 'Security features not supported',
         'X.7.5' => 'Cryptographic failure',
         'X.7.6' => 'Cryptographic algorithm not supported',
         'X.7.7' => 'Message integrity failure'
     }

    # Returns HTML, of extra comment to put by attachment
    def extra_note
        # For delivery status notification attachments, extract the status and
        # look up what it means in the DSN table.
        if @content_type == 'message/delivery-status'
            if !@body.match(/Status:\s+([0-9]+\.([0-9]+\.[0-9]+))\s+/)
                return ""
            end
            dsn = $1
            dsn_part = 'X.' + $2

            dsn_message = ""
            if DsnToMessage.include?(dsn_part)
                dsn_message = " (" + DsnToMessage[dsn_part] + ")"
            end

            return "<br><em>DSN: " + dsn + dsn_message + "</em>"
        end
        return ""
    end

    # Called by controller so old filenames still work
    def old_display_filename
        filename = self._internal_display_filename

        # Convert weird spaces (e.g. \n) to normal ones
        filename = filename.gsub(/\s/, " ")
        # Remove slashes, they mess with URLs
        filename = filename.gsub(/\//, "-")

        return filename
    end 

    # XXX changing this will break existing URLs, so have a care - maybe
    # make another old_display_filename see above
    def display_filename
        filename = self._internal_display_filename

        # Sometimes filenames have e.g. %20 in - no point butchering that
        # (without unescaping it, this would remove the % and leave 20s in there)
        filename = CGI.unescape(filename)

        # Remove weird spaces
        filename = filename.gsub(/\s+/, " ")
        # Remove non-alphabetic characters
        filename = filename.gsub(/[^A-Za-z0-9.]/, " ")
        # Remove spaces near dots
        filename = filename.gsub(/\s*\.\s*/, ".")
        # Compress adjacent spaces down to a single one
        filename = filename.gsub(/\s+/, " ")
        filename = filename.strip

        return filename
    end

    def _internal_display_filename
        calc_ext = AlaveteliFileTypes.mimetype_to_extension(@content_type)

        if @filename 
            # Put right extension on if missing
            if !filename.match(/\.#{calc_ext}$/) && calc_ext
                filename + "." + calc_ext
            else
                filename
            end
        else
            if !calc_ext
                calc_ext = "bin"
            end
            if @within_rfc822_subject
                @within_rfc822_subject + "." + calc_ext
            else
                "attachment." + calc_ext
            end
        end
    end

    # Size to show next to the download link for the attachment
    def display_size
        s = self.body.size

        if s > 1024 * 1024
            return  sprintf("%.1f", s.to_f / 1024 / 1024) + 'M'
        else
            return (s / 1024).to_s + 'K'
        end
    end

    # Whether this type can be shown in the Google Docs Viewer.
    # The full list of supported types can be found at
    #   https://docs.google.com/support/bin/answer.py?hl=en&answer=1189935
    def has_google_docs_viewer?
        return !! {
            "application/pdf" => true, # .pdf
            "image/tiff" => true, # .tiff
            
            "application/vnd.ms-word" => true, # .doc
            "application/vnd.openxmlformats-officedocument.wordprocessingml.document" => true, # .docx
            
            "application/vnd.ms-powerpoint" => true, # .ppt
            "application/vnd.openxmlformats-officedocument.presentationml.presentation" => true, # .pptx
            
            "application/vnd.ms-excel" => true, # .xls
            "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" => true, # .xlsx
            
        } [self.content_type]
    end

    # Whether this type has a "View as HTML"
    def has_body_as_html?
        return (
            !!{
                "text/plain" => true,
                "application/rtf" => true,
            }[self.content_type] or
            self.has_google_docs_viewer?
        )
    end

    # Name of type of attachment type - only valid for things that has_body_as_html?
    def name_of_content_type
        return {
            "text/plain" => "Text file",
            'application/rtf' => "RTF file",
            
            'application/pdf' => "PDF file",
            'image/tiff' => "TIFF image",
            
            'application/vnd.ms-word' => "Word document",
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document' => "Word document",
            
            'application/vnd.ms-powerpoint' => "PowerPoint presentation",
            'application/vnd.openxmlformats-officedocument.presentationml.presentation' => "PowerPoint presentation",
            
            'application/vnd.ms-excel' => "Excel spreadsheet",
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' => "Excel spreadsheet",
        }[self.content_type]
    end

    # For "View as HTML" of attachment
    def body_as_html(dir)
        html = nil
        wrapper_id = "wrapper"

        # simple cases, can never fail
        if self.content_type == 'text/plain'
            text = self.body.strip
            text = CGI.escapeHTML(text)
            text = MySociety::Format.make_clickable(text)
            html = text.gsub(/\n/, '<br>')
            return '<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
   "http://www.w3.org/TR/html4/loose.dtd"><html><head><title></title></head><body>' + html + "</body></html>", wrapper_id
        end

        # the extractions will also produce image files, which go in the
        # current directory, so change to the directory the function caller
        # wants everything in
        Dir.chdir(dir) do
            tempfile = Tempfile.new('foiextract', '.')
            tempfile.print self.body
            tempfile.flush

            if self.content_type == 'application/pdf'
                IO.popen("#{`which pdftohtml`.chomp} -nodrm -zoom 1.0 -stdout -enc UTF-8 -noframes " + tempfile.path + "", "r") do |child|
                    html = child.read()
                end
            elsif self.content_type == 'application/rtf'
                IO.popen("/usr/bin/unrtf --html " + tempfile.path + "", "r") do |child|
                    html = child.read()
                end
            elsif self.has_google_docs_viewer?
                html = '' # force error and using Google docs viewer
            else
                raise "No HTML conversion available for type " + self.content_type
            end

            tempfile.close
            tempfile.delete
        end

        # We need to look at:
        # a) Any error code
        # b) The output size, as pdftohtml does not return an error code upon error.
        # c) For cases when there is no text in the body of the HTML, or
        # images, so nothing will be rendered. This is to detect some bug in
        # pdftohtml, which sometimes makes it return just <hr>s and no other
        # content.
        html.match(/(\<body[^>]*\>.*)/mi)
        body = $1.to_s
        body_without_tags = body.gsub(/\s+/,"").gsub(/\<[^\>]*\>/, "")
        contains_images = html.match(/<img/mi) ? true : false
        if !$?.success? || html.size == 0 || (body_without_tags.size == 0 && !contains_images)
            ret = "<html><head></head><body>";
            if self.has_google_docs_viewer?
                wrapper_id = "wrapper_google_embed"
                ret = ret + "<iframe src='http://docs.google.com/viewer?url=<attachment-url-here>&embedded=true' width='100%' height='100%' style='border: none;'></iframe>";
            else 
                ret = ret + "<p>Sorry, we were unable to convert this file to HTML. Please use the download link at the top right.</p>"
            end
            ret = ret + "</body></html>"
            return ret, wrapper_id
        end

        return html, wrapper_id
    end

end


class IncomingMessage < ActiveRecord::Base
    belongs_to :info_request
    validates_presence_of :info_request

    validates_presence_of :raw_email

    has_many :outgoing_message_followups, :foreign_key => 'incoming_message_followup_id', :class_name => 'OutgoingMessage'

    has_many :info_request_events # never really has many, but could in theory

    belongs_to :raw_email

    # See binary_mask_stuff function below. It just test for inclusion
    # in this hash, not the value of the right hand side.
    DoNotBinaryMask = {
        'image/tiff' => 1,
        'image/gif' => 1,
        'image/jpeg' => 1,
        'image/png' => 1,
        'image/bmp' => 1,
        'application/zip' => 1,
    }

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
            _count_parts_recursive(self.mail)
            # we carry on using these numeric ids for attachments uudecoded from within text parts
            @count_first_uudecode_count = @count_parts_count
            @parts_counted = true
        end
    end
    def _count_parts_recursive(part)
        if part.multipart?
            part.parts.each do |p|
                _count_parts_recursive(p)
            end
        else
            part_filename = TMail::Mail.get_part_file_name(part)
            begin
                if part.content_type == 'message/rfc822'
                    # An email attached as text
                    # e.g. http://www.whatdotheyknow.com/request/64/response/102
                    part.rfc822_attachment = TMail::Mail.parse(part.body)
                elsif part.content_type == 'application/vnd.ms-outlook' || part_filename && AlaveteliFileTypes.filename_to_mimetype(part_filename) == 'application/vnd.ms-outlook'
                    # An email attached as an Outlook file
                    # e.g. http://www.whatdotheyknow.com/request/chinese_names_for_british_politi
                    msg = Mapi::Msg.open(StringIO.new(part.body))
                    part.rfc822_attachment = TMail::Mail.parse(msg.to_mime.to_s)
                elsif part.content_type == 'application/ms-tnef' 
                    # A set of attachments in a TNEF file
                    part.rfc822_attachment = TNEF.as_tmail(part.body)
                end
            rescue
                # If attached mail doesn't parse, treat it as text part
                part.rfc822_attachment = nil
            else
                unless part.rfc822_attachment.nil?
                    _count_parts_recursive(part.rfc822_attachment)
                end
            end
            if part.rfc822_attachment.nil?
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
    def mask_special_emails!(text)
        # XXX can later display some of these special emails as actual emails,
        # if they are public anyway.  For now just be precautionary and only
        # put in descriptions of them in square brackets.
        if self.info_request.public_body.is_followupable?
            text.gsub!(self.info_request.public_body.request_email, "[" + self.info_request.public_body.short_or_long_name + " request email]")
        end
        text.gsub!(self.info_request.incoming_email, "[FOI #" + self.info_request.id.to_s + " email]")
        text.gsub!(MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost'), "[#{MySociety::Config.get('SITE_NAME', 'Alaveteli')} contact email]")
    end

    # Replaces all email addresses in (possibly binary data) with equal length alternative ones.
    # Also replaces censor items
    def binary_mask_stuff!(text, content_type)
        # See if content type is one that we mask - things like zip files and
        # images may get broken if we try to. We err on the side of masking too
        # much, as many unknown types will really be text.
        if DoNotBinaryMask.include?(content_type)
            return
        end

        # Special cases for some content types
        if content_type == 'application/pdf'
            uncompressed_text = nil
            IO.popen("#{`which pdftk`.chomp} - output - uncompress", "r+") do |child|
                child.write(text)
                child.close_write()
                uncompressed_text = child.read()
            end
            # if we managed to uncompress the PDF...
            if !uncompressed_text.nil? && !uncompressed_text.empty?
                # then censor stuff (making a copy so can compare again in a bit)
                censored_uncompressed_text = uncompressed_text.dup
                self._binary_mask_stuff_internal!(censored_uncompressed_text)
                # if the censor rule removed something...
                if censored_uncompressed_text != uncompressed_text
                    # then use the altered file (recompressed)
                    recompressed_text = nil
                    if MySociety::Config.get('USE_GHOSTSCRIPT_COMPRESSION') == true
                        command = "gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/screen -dNOPAUSE -dQUIET -dBATCH -sOutputFile=- -"
                    else
                        command = "#{`which pdftk`.chomp} - output - compress"
                    end
                    IO.popen(command, "r+") do |child|
                        child.write(censored_uncompressed_text)
                        child.close_write()
                        recompressed_text = child.read()
                    end
                    if recompressed_text.nil? || recompressed_text.empty?
                        # buggy versions of pdftk sometimes fail on
                        # compression, I don't see it's a disaster in
                        # these cases to save an uncompressed version?
                        recompressed_text = censored_uncompressed_text                        
                        logger.warn "Unable to compress PDF; problem with your pdftk version?"
                    end
                    if !recompressed_text.nil? && !recompressed_text.empty?
                        text[0..-1] = recompressed_text # [0..-1] makes it change the 'text' string in place
                    end
                end
            end
            return 
        end

        self._binary_mask_stuff_internal!(text) 
    end

    # Used by binary_mask_stuff - replace text in place
    def _binary_mask_stuff_internal!(text)
        # Keep original size, so can check haven't resized it
        orig_size = text.size

        # Replace ASCII email addresses...
        text.gsub!(MySociety::Validate.email_find_regexp) do |email| 
            email.gsub(/[^@.]/, 'x')
        end

        # And replace UCS-2 ones (for Microsoft Office documents)...
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
        self.info_request.apply_censor_rules_to_binary!(text)

        raise "internal error in binary_mask_stuff" if text.size != orig_size
    end

    # Removes censored stuff from from HTML conversion of downloaded binaries
    def html_mask_stuff!(html)
        self.mask_special_emails!(html)
        self.remove_privacy_sensitive_things!(html)
    end

    # Lotus notes quoting yeuch!
    def remove_lotus_quoting(text, replacement = "FOLDED_QUOTED_SECTION")
        text = text.dup
        name = Regexp.escape(self.info_request.user.name)

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
    def remove_privacy_sensitive_things!(text)
        # Remove any email addresses - we don't want bounce messages to leak out
        # either the requestor's email address or the request's response email
        # address out onto the internet
        text.gsub!(MySociety::Validate.email_find_regexp, "[email address]")

        # Mobile phone numbers
        # http://www.whatdotheyknow.com/request/failed_test_purchases_off_licenc#incoming-1013
        # http://www.whatdotheyknow.com/request/selective_licensing_statistics_i#incoming-550
        # http://www.whatdotheyknow.com/request/common_purpose_training_graduate#incoming-774
        text.gsub!(/(Mobile|Mob)([\s\/]*(Fax|Tel))*\s*:?[\s\d]*\d/, "[mobile number]")

        # Specific removals # XXX remove these and turn them into censor rules in database
        # http://www.whatdotheyknow.com/request/total_number_of_objects_in_the_n_6
        text.gsub!(/\*\*\*+\nPolly Tucker.*/ms, "")
        # http://www.whatdotheyknow.com/request/cctv_data_retention_and_use
        text.gsub!(/Andy 079.*/, "Andy [mobile number]")
        # http://www.whatdotheyknow.com/request/how_do_the_pct_deal_with_retirin_113
        text.gsub!(/(Complaints and Corporate Affairs Officer)\s+Westminster Primary Care Trust.+/ms, "\\1")

        # Remove WhatDoTheyKnow signup links
        domain = MySociety::Config.get('DOMAIN')
        text.gsub!(/http:\/\/#{domain}\/c\/[^\s]+/, "[WDTK login link]")

        # Remove Home Office survey links
        # e.g. http://www.whatdotheyknow.com/request/serious_crime_act_2007_section_7#incoming-12650
        if self.info_request.public_body.url_name == 'home_office'
            text.gsub!(/Your password:-\s+[^\s]+/, '[password]')
            text.gsub!(/Password=[^\s]+/, '[password]')
        end

        # Remove things from censor rules
        self.info_request.apply_censor_rules_to_text!(text)
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

        ['-', '_', '*', '#'].each do |scorechar|
            score = /(?:[#{scorechar}]\s*){8,}/
            text.sub!(/(Disclaimer\s+)?  # appears just before
                        (
                            \s*#{score}\n(?:(?!#{score}\n).)*? # top line
                            (disclaimer:\n|confidential|received\sthis\semail\sin\serror|virus|intended\s+recipient|monitored\s+centrally|intended\s+(for\s+|only\s+for\s+use\s+by\s+)the\s+addressee|routinely\s+monitored|MessageLabs|unauthorised\s+use)
                            .*?(?:#{score}|\z) # bottom line OR end of whole string (for ones with no terminator XXX risky)
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

    # Internal function
    def _get_censored_part_file_name(mail)
        part_file_name = TMail::Mail.get_part_file_name(mail)
        if part_file_name.nil?
            return nil
        end
        part_file_name = part_file_name.dup
        self.info_request.apply_censor_rules_to_text!(part_file_name)
        return part_file_name
    end

    # (This risks losing info if the unchosen alternative is the only one to contain 
    # useful info, but let's worry about that another time)
    def get_attachment_leaves
        return _get_attachment_leaves_recursive(self.mail)
    end
    def _get_attachment_leaves_recursive(curr_mail, within_rfc822_attachment = nil)
        leaves_found = []
        if curr_mail.multipart?
            if curr_mail.parts.size == 0
                raise "no parts on multipart mail"
            end

            if curr_mail.sub_type == 'alternative'
                # Choose best part from alternatives
                best_part = nil
                # Take the last text/plain one, or else the first one
                curr_mail.parts.each do |m|
                    if not best_part
                        best_part = m
                    elsif m.content_type == 'text/plain'
                        best_part = m
                    end
                end
                # Take an HTML one as even higher priority. (They tend
                # to render better than text/plain, e.g. don't wrap links here:
                # http://www.whatdotheyknow.com/request/amount_and_cost_of_freedom_of_in#incoming-72238 )
                curr_mail.parts.each do |m|
                    if m.content_type == 'text/html'
                        best_part = m
                    end
                end
                leaves_found += _get_attachment_leaves_recursive(best_part, within_rfc822_attachment)
            else
                # Add all parts
                curr_mail.parts.each do |m|
                    leaves_found += _get_attachment_leaves_recursive(m, within_rfc822_attachment)
                end
            end
        else
            # XXX Yuck. this section alters various content_type's. That puts
            # it into conflict with ensure_parts_counted which it has to be
            # called both before and after.  It will fail with cases of
            # attachments of attachments etc.

            # Don't allow nil content_types
            if curr_mail.content_type.nil?
                curr_mail.content_type = 'application/octet-stream'
            end
            # PDFs often come with this mime type, fix it up for view code
            if curr_mail.content_type == 'application/octet-stream'
                part_file_name = self._get_censored_part_file_name(curr_mail)
                calc_mime = AlaveteliFileTypes.filename_and_content_to_mimetype(part_file_name, curr_mail.body)
                if calc_mime
                    curr_mail.content_type = calc_mime
                end
            end 

            # Use standard content types for Word documents etc.
            curr_mail.content_type = normalise_content_type(curr_mail.content_type)
            if curr_mail.content_type == 'message/rfc822'
                ensure_parts_counted # fills in rfc822_attachment variable
                if curr_mail.rfc822_attachment.nil?
                    # Attached mail didn't parse, so treat as text
                    curr_mail.content_type = 'text/plain'
                end
            end
            if curr_mail.content_type == 'application/vnd.ms-outlook' || curr_mail.content_type == 'application/ms-tnef'
                ensure_parts_counted # fills in rfc822_attachment variable
                if curr_mail.rfc822_attachment.nil?
                    # Attached mail didn't parse, so treat as binary
                    curr_mail.content_type = 'application/octet-stream'
                end
            end

            # If the part is an attachment of email
            if curr_mail.content_type == 'message/rfc822' || curr_mail.content_type == 'application/vnd.ms-outlook' || curr_mail.content_type == 'application/ms-tnef'
                ensure_parts_counted # fills in rfc822_attachment variable
                leaves_found += _get_attachment_leaves_recursive(curr_mail.rfc822_attachment, curr_mail.rfc822_attachment)
            else
                # Store leaf
                curr_mail.within_rfc822_attachment = within_rfc822_attachment
                leaves_found += [curr_mail]
            end
        end
        return leaves_found
    end

    # Removes anything cached about the object in the database, and saves
    def clear_in_database_caches!
        self.cached_attachment_text_clipped = nil
        self.cached_main_body_text_unfolded = nil
        self.cached_main_body_text_folded = nil
        self.save!
    end

    # Internal function to cache two sorts of main body text.
    # Cached as loading raw_email can be quite huge, and need this for just
    # search results
    def _cache_main_body_text
        text = self.get_main_body_text_internal

        # Strip the uudecode parts from main text
        # - this also effectively does a .dup as well, so text mods don't alter original
        text = text.split(/^begin.+^`\n^end\n/sm).join(" ")

        if text.size > 1000000 # 1 MB ish
            raise "main body text more than 1 MB, need to implement clipping like for attachment text, or there is some other MIME decoding problem or similar"
        end

        # remove emails for privacy/anti-spam reasons
        self.mask_special_emails!(text)
        self.remove_privacy_sensitive_things!(text)

        # Remove existing quoted sections
        folded_quoted_text = self.remove_lotus_quoting(text, 'FOLDED_QUOTED_SECTION')
        folded_quoted_text = IncomingMessage.remove_quoted_sections(text, "FOLDED_QUOTED_SECTION")

        self.cached_main_body_text_unfolded = text
        self.cached_main_body_text_folded = folded_quoted_text
        self.save!
    end
    # Returns body text from main text part of email, converted to UTF-8, with uudecode removed,
    # emails and privacy sensitive things remove, censored, and folded to remove excess quoted text
    # (marked with FOLDED_QUOTED_SECTION)
    # XXX returns a .dup of the text, so calling functions can in place modify it
    def get_main_body_text_folded
        if self.cached_main_body_text_folded.nil?
            self._cache_main_body_text
        end
        return self.cached_main_body_text_folded
    end
    def get_main_body_text_unfolded
        if self.cached_main_body_text_unfolded.nil?
            self._cache_main_body_text
        end
        return self.cached_main_body_text_unfolded
    end
    # Returns body text from main text part of email, converted to UTF-8
    def get_main_body_text_internal
        main_part = get_main_body_text_part
        return _convert_part_body_to_text(main_part)
    end
    # Given a main text part, converts it to text
    def _convert_part_body_to_text(part)
        if part.nil?
            text = "[ Email has no body, please see attachments ]"
            text_charset = "utf-8"
        else
            text = part.body
            text_charset = part.charset
            if part.content_type == 'text/html'
                # e.g. http://www.whatdotheyknow.com/request/35/response/177
                # XXX This is a bit of a hack as it is calling a convert to text routine.
                # Could instead call a sanitize HTML one.
                text = self.class._get_attachment_text_internal_one_file(part.content_type, text)
            end
        end

        # Charset conversion, turn everything into UTF-8
        if not text_charset.nil?
            begin
                # XXX specially convert unicode pound signs, was needed here
                # http://www.whatdotheyknow.com/request/88/response/352
                text = text.gsub("£", Iconv.conv(text_charset, 'utf-8', '£')) 
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
                    text = Iconv.conv('utf-8//IGNORE', 'utf-8', text) + 
                        _("\n\n[ {{site_name}} note: The above text was badly encoded, and has had strange characters removed. ]", 
                        :site_name => MySociety::Config.get('SITE_NAME', 'Alaveteli'))
                end
            end
        end
        
        # An assertion that we have ended up with UTF-8 XXX can remove as this should
        # always be fine if code above is
        Iconv.conv('utf-8', 'utf-8', text)

        # Fix DOS style linefeeds to Unix style ones (or other later regexps won't work)
        # Needed for e.g. http://www.whatdotheyknow.com/request/60/response/98
        text = text.gsub(/\r\n/, "\n")

        # Compress extra spaces down to save space, and to stop regular expressions
        # breaking in strange extreme cases. e.g. for
        # http://www.whatdotheyknow.com/request/spending_on_consultants
        text = text.gsub(/ +/, " ")

        return text
    end
    # Returns part which contains main body text, or nil if there isn't one
    def get_main_body_text_part
        leaves = get_attachment_leaves
        
        # Find first part which is text/plain or text/html
        # (We have to include HTML, as increasingly there are mail clients that
        # include no text alternative for the main part, and we don't want to
        # instead use the first text attachment 
        # e.g. http://www.whatdotheyknow.com/request/list_of_public_authorties)
        leaves.each do |p|
            if p.content_type == 'text/plain' or p.content_type == 'text/html'
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
        if AlaveteliFileTypes.mimetype_to_extension(p.content_type)
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
        # we don't use get_main_body_text_internal, as we want to avoid charset
        # conversions, since /usr/bin/uudecode needs to deal with those.
        # e.g. for https://secure.mysociety.org/admin/foi/request/show_raw_email/24550
        main_part = get_main_body_text_part
        if main_part.nil?
            return []
        end
        text = main_part.body

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
            self.info_request.apply_censor_rules_to_text!(attachment.filename)
            calc_mime = AlaveteliFileTypes.filename_and_content_to_mimetype(attachment.filename, attachment.body)
            if calc_mime
                calc_mime = normalise_content_type(calc_mime)
                attachment.content_type = calc_mime
            else
                attachment.content_type = 'application/octet-stream'
            end
            attachments += [attachment]
        end
        
        return attachments
    end

    # Returns all attachments for use in display code
    # XXX is this called multiple times and should be cached?
    def get_attachments_for_display
        main_part = get_main_body_text_part
        leaves = get_attachment_leaves

        # XXX we have to call ensure_parts_counted after get_attachment_leaves
        # which is really messy.
        ensure_parts_counted

        attachments = []
        for leaf in leaves
            if leaf != main_part
                attachment = FOIAttachment.new

                attachment.body = leaf.body
                # As leaf.body causes MIME decoding which uses lots of RAM, do garbage collection here
                # to prevent excess memory use. XXX not really sure if this helps reduce
                # peak RAM use overall. Anyway, maybe there is something better to do than this.
                GC.start 

                attachment.filename = _get_censored_part_file_name(leaf)
                if leaf.within_rfc822_attachment
                    attachment.within_rfc822_subject = leaf.within_rfc822_attachment.subject
                    # Test to see if we are in the first part of the attached
                    # RFC822 message and it is text, if so add headers.
                    # XXX should probably use hunting algorithm to find main text part, rather than
                    # just expect it to be first. This will do for now though.
                    # Example request that needs this:
                    # http://www.whatdotheyknow.com/request/2923/response/7013/attach/2/Cycle%20Path%20Bank.txt
                    if leaf.within_rfc822_attachment == leaf && leaf.content_type == 'text/plain'
                        headers = ""
                        for header in [ 'Date', 'Subject', 'From', 'To', 'Cc' ]
                            if leaf.within_rfc822_attachment.header.include?(header.downcase)
                                header_value = leaf.within_rfc822_attachment.header[header.downcase]
                                # Example message which has a blank Date header:
                                # http://www.whatdotheyknow.com/request/30747/response/80253/attach/html/17/Common%20Purpose%20Advisory%20Group%20Meeting%20Tuesday%202nd%20March.txt.html
                                if !header_value.blank?
                                    headers = headers + header + ": " + header_value.to_s + "\n"
                                end
                            end
                        end
                        # XXX call _convert_part_body_to_text here, but need to get charset somehow
                        # e.g. http://www.whatdotheyknow.com/request/1593/response/3088/attach/4/Freedom%20of%20Information%20request%20-%20car%20oval%20sticker:%20Article%2020,%20Convention%20on%20Road%20Traffic%201949.txt
                        attachment.body = headers + "\n" + attachment.body

                        # This is quick way of getting all headers, but instead we only add some a) to
                        # make it more usable, b) as at least one authority accidentally leaked security
                        # information into a header.
                        #attachment.body = leaf.within_rfc822_attachment.port.to_s
                    end
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
        text = get_main_body_text_unfolded
        folded_quoted_text = get_main_body_text_folded

        # Remove quoted sections, adding HTML. XXX The FOLDED_QUOTED_SECTION is
        # a nasty hack so we can escape other HTML before adding the unfold
        # links, without escaping them. Rather than using some proper parser
        # making a tree structure (I don't know of one that is to hand, that
        # works well in this kind of situation, such as with regexps).
        if collapse_quoted_sections
            text = folded_quoted_text
        end
        text = MySociety::Format.simplify_angle_bracketed_urls(text)
        text = CGI.escapeHTML(text)
        text = MySociety::Format.make_clickable(text, :contract => 1)
        text.gsub!(/\[(email address|mobile number)\]/, '[<a href="/help/officers#mobiles">\1</a>]')
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
        # Get the body text with emails and quoted sections removed
        text = get_main_body_text_folded
        text.gsub!("FOLDED_QUOTED_SECTION", " ")
        text.strip!
        raise "internal error" if text.nil?
        return text
    end

    MAX_ATTACHMENT_TEXT_CLIPPED = 1000000 # 1Mb ish

    # Returns text version of attachment text
    def get_attachment_text_full
        text = self._get_attachment_text_internal
        self.mask_special_emails!(text)
        self.remove_privacy_sensitive_things!(text)
        # This can be useful for memory debugging
        #STDOUT.puts 'xxx '+ MySociety::DebugHelpers::allocated_string_size_around_gc
        
        # Save clipped version for snippets
        if self.cached_attachment_text_clipped.nil?
            self.cached_attachment_text_clipped = text[0..MAX_ATTACHMENT_TEXT_CLIPPED]
            self.save!
        end
        
        return text
    end
    # Returns a version reduced to a sensible maximum size - this
    # is for performance reasons when showing snippets in search results.
    def get_attachment_text_clipped
        if self.cached_attachment_text_clipped.nil?
            # As side effect, get_attachment_text_full makes snippet text
            attachment_text = self.get_attachment_text_full
            raise "internal error" if self.cached_attachment_text_clipped.nil?
        end

        return self.cached_attachment_text_clipped
    end
    def IncomingMessage._get_attachment_text_internal_one_file(content_type, body)
        text = ''
        # XXX - tell all these command line tools to return utf-8
        if content_type == 'text/plain'
            text += body + "\n\n"
        else
            tempfile = Tempfile.new('foiextract')
            tempfile.print body
            tempfile.flush
            if content_type == 'application/vnd.ms-word'
                AlaveteliExternalCommand.run(`which wvText`.chomp, tempfile.path, tempfile.path + ".txt")
                # Try catdoc if we get into trouble (e.g. for InfoRequestEvent 2701)
                if not File.exists?(tempfile.path + ".txt")
                    AlaveteliExternalCommand.run(`which catdoc`.chomp, tempfile.path, :append_to => text)
                else
                    text += File.read(tempfile.path + ".txt") + "\n\n"
                    File.unlink(tempfile.path + ".txt")
                end
            elsif content_type == 'application/rtf'
                # catdoc on RTF prodcues less comments and extra bumf than --text option to unrtf
                AlaveteliExternalCommand.run(`which catdoc`.chomp, tempfile.path, :append_to => text)
            elsif content_type == 'text/html'
                # lynx wordwraps links in its output, which then don't get formatted properly
                # by Alaveteli. We use elinks instead, which doesn't do that.
                AlaveteliExternalCommand.run(`which elinks`.chomp, "-eval", "'set document.codepage.assume = \"utf-8\"'", "-dump-charset", "utf-8", "-force-html", "-dump",
                    tempfile.path, :append_to => text)
            elsif content_type == 'application/vnd.ms-excel'
                # Bit crazy using /usr/bin/strings - but xls2csv, xlhtml and
                # py_xls2txt only extract text from cells, not from floating
                # notes. catdoc may be fooled by weird character sets, but will
                # probably do for UK FOI requests.
                AlaveteliExternalCommand.run("/usr/bin/strings", tempfile.path, :append_to => text)
            elsif content_type == 'application/vnd.ms-powerpoint'
                # ppthtml seems to catch more text, but only outputs HTML when
                # we want text, so just use catppt for now
                AlaveteliExternalCommand.run(`which catppt`.chomp, tempfile.path, :append_to => text)
            elsif content_type == 'application/pdf'
                AlaveteliExternalCommand.run(`which pdftotext`.chomp, tempfile.path, "-", :append_to => text)
            elsif content_type == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
                # This is Microsoft's XML office document format.
                # Just pull out the main XML file, and strip it of text.
                xml = AlaveteliExternalCommand.run("/usr/bin/unzip", "-qq", "-c", tempfile.path, "word/document.xml")
                if !xml.nil?
                    doc = REXML::Document.new(xml)
                    text += doc.each_element( './/text()' ){}.join(" ")
                end
            elsif content_type == 'application/zip'
                # recurse into zip files
                begin
                    zip_file = Zip::ZipFile.open(tempfile.path)
                    text += IncomingMessage._get_attachment_text_from_zip_file(zip_file)
                    zip_file.close()
                rescue
                    $stderr.puts("Error processing zip file: #{$!.inspect}")
                end
            end
            tempfile.close
        end

        return text
    end
    def IncomingMessage._get_attachment_text_from_zip_file(zip_file)
        text = ""
        for entry in zip_file
            if entry.file?
                filename = entry.to_s
                begin 
                    body = entry.get_input_stream.read
                rescue
                    # move to next attachment silently if there were problems
                    # XXX really should reduce this to specific exceptions?
                    # e.g. password protected
                    next
                end
                calc_mime = AlaveteliFileTypes.filename_to_mimetype(filename)
                if calc_mime
                    content_type = calc_mime
                else
                    content_type = 'application/octet-stream'
                end
            
                text += _get_attachment_text_internal_one_file(content_type, body)
            end
        end
        return text
    end
    def _get_attachment_text_internal
        # Extract text from each attachment
        text = ''
        attachments = self.get_attachments_for_display
        for attachment in attachments
            text += IncomingMessage._get_attachment_text_internal_one_file(attachment.content_type, attachment.body)
        end
        # Remove any bad characters
        text = Iconv.conv('utf-8//IGNORE', 'utf-8', text)
        return text
    end

    # Returns text for indexing
    def get_text_for_indexing_full
        return get_body_for_quoting + "\n\n" + get_attachment_text_full
    end
    # Used for excerpts in search results, when loading full text would be too slow
    def get_text_for_indexing_clipped
        return get_body_for_quoting + "\n\n" + get_attachment_text_clipped
    end

    # Returns the name of the person the incoming message is from, or nil if
    # there isn't one or if there is only an email address. XXX can probably
    # remove from_name_if_present (which is a monkey patch) by just calling
    # .from_addrs[0].name here instead? 
    def safe_mail_from
        name = self.mail.from_name_if_present
        if name.nil?
            return nil
        end
        name = name.dup
        self.info_request.apply_censor_rules_to_text!(name)
        return name
    end

    def mail_from_domain
        return PublicBody.extract_domain_from_email(self.mail.from_addrs[0].spec)
    end


    # Has message arrived "recently"?
    def recently_arrived
        (Time.now - self.created_at) <= 3.days
    end

    def fully_destroy
        ActiveRecord::Base.transaction do
            for o in self.outgoing_message_followups
                o.incoming_message_followup = nil
                o.save!
            end
            info_request_event = InfoRequestEvent.find_by_incoming_message_id(self.id)
            info_request_event.track_things_sent_emails.each { |a| a.destroy }
            info_request_event.user_info_request_sent_alerts.each { |a| a.destroy }
            info_request_event.destroy
            self.raw_email.destroy_file_representation!
            self.destroy
        end
    end

    # Search all info requests for 
    def IncomingMessage.find_all_unknown_mime_types
        for incoming_message in IncomingMessage.find(:all)
            for attachment in incoming_message.get_attachments_for_display
                raise "internal error incoming_message " + incoming_message.id.to_s if attachment.content_type.nil?
                if AlaveteliFileTypes.mimetype_to_extension(attachment.content_type).nil?
                    $stderr.puts "Unknown type for /request/" + incoming_message.info_request.id.to_s + "#incoming-"+incoming_message.id.to_s
                    $stderr.puts " " + attachment.filename.to_s + " " + attachment.content_type.to_s
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
            ext = AlaveteliFileTypes.mimetype_to_extension(attachment.content_type)
            ext = File.extname(attachment.filename).gsub(/^[.]/, "") if ext.nil? && !attachment.filename.nil?
            ret[ext] = 1 if !ext.nil?
        end
        return ret.keys.join(" ")
    end
    # Return space separated list of all file extensions known
    def IncomingMessage.get_all_file_extensions
        return AlaveteliFileTypes.all_extensions.join(" ")
    end

    # Return false if for some reason this is a message that we shouldn't let them reply to
    def valid_to_reply_to?
        # check validity of email
        if self.mail.from_addrs.nil? || self.mail.from_addrs.size == 0
            return false
        end
        email = self.mail.from_addrs[0].spec
        if !MySociety::Validate.is_valid_email(email)
            return false
        end

        # reject postmaster - authorities seem to nearly always not respond to
        # email to postmaster, and it tends to only happen after delivery failure.
        # likewise Mailer-Daemon, Auto_Reply...
        prefix = email
        prefix =~ /^(.*)@/
        prefix = $1
        if !prefix.nil? && prefix.downcase.match(/^(postmaster|mailer-daemon|auto_reply|do.?not.?reply|no.reply)$/)
            return false
        end
        if !self.mail['return-path'].nil? && self.mail['return-path'].addr == "<>"
            return false
        end
        if !self.mail['auto-submitted'].nil? && !self.mail['auto-submitted'].keys.empty?
            return false
        end
        return true
    end

    def normalise_content_type(content_type)
        # e.g. http://www.whatdotheyknow.com/request/93/response/250
        if content_type == 'application/excel' or content_type == 'application/msexcel' or content_type == 'application/x-ms-excel'
            content_type = 'application/vnd.ms-excel'
        end
        if content_type == 'application/mspowerpoint' or content_type == 'application/x-ms-powerpoint'
            content_type = 'application/vnd.ms-powerpoint' 
        end
        if content_type == 'application/msword' or content_type == 'application/x-ms-word'
            content_type = 'application/vnd.ms-word'
        end
        if content_type == 'application/x-zip-compressed'
            content_type = 'application/zip'
        end

        # e.g. http://www.whatdotheyknow.com/request/copy_of_current_swessex_scr_opt#incoming-9928
        if content_type == 'application/acrobat'
            content_type = 'application/pdf'
        end

        return content_type
    end
    private :normalise_content_type

end


