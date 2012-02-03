# == Schema Information
# Schema version: 108
#
# Table name: foi_attachments
#
#  id                    :integer         not null, primary key
#  content_type          :text
#  filename              :text
#  charset               :text
#  display_size          :text
#  url_part_number       :integer
#  within_rfc822_subject :text
#  incoming_message_id   :integer
#  hexdigest             :string(32)
#

# encoding: UTF-8

# models/foi_attachment.rb:
# An attachment to an email (IncomingMessage)
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
# This is the type which is used to send data about attachments to the view

require 'digest'

class FoiAttachment < ActiveRecord::Base
    belongs_to :incoming_message
    validates_presence_of :content_type
    validates_presence_of :filename
    validates_presence_of :display_size

    before_validation :ensure_filename!, :only => [:filename]
    before_destroy :delete_cached_file!

    BODY_MAX_TRIES = 3
    BODY_MAX_DELAY = 5

    def directory
        rails_env = ENV['RAILS_ENV']
        if rails_env.nil? || rails_env.empty?
            raise "$RAILS_ENV is not set"
        end
        base_dir = File.join(File.dirname(__FILE__), "../../cache", "attachments_#{rails_env}")
        return File.join(base_dir, self.hexdigest[0..2])
    end

    def filepath
        File.join(self.directory, self.hexdigest)
    end

    def delete_cached_file!
        begin
            @cached_body = nil
            File.delete(self.filepath)
        rescue
        end
    end

    def body=(d)
        self.hexdigest = Digest::MD5.hexdigest(d)
        if !File.exists?(self.directory)
            FileUtils.mkdir_p self.directory
        end
        File.open(self.filepath, "wb") { |file|
            file.write d
        }
        update_display_size!
        @cached_body = d
    end

    def body
        if @cached_body.nil?
            tries = 0
            delay = 1
            begin
                @cached_body = File.open(self.filepath, "rb" ).read
            rescue Errno::ENOENT
                # we've lost our cached attachments for some reason.  Reparse them.
                if tries > BODY_MAX_TRIES
                    raise
                else
                    sleep delay
                end
                tries += 1
                delay *= 2
                delay = BODY_MAX_DELAY if delay > BODY_MAX_DELAY
                force = true
                self.incoming_message.parse_raw_email!(force)
                retry
            end
        end
        return @cached_body
    end

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
        filename = self.filename

        # Convert weird spaces (e.g. \n) to normal ones
        filename = filename.gsub(/\s/, " ")
        # Remove slashes, they mess with URLs
        filename = filename.gsub(/\//, "-")

        return filename
    end 

    # XXX changing this will break existing URLs, so have a care - maybe
    # make another old_display_filename see above
    def display_filename
        filename = self.filename
        if !self.incoming_message.nil?
            self.incoming_message.info_request.apply_censor_rules_to_text!(filename)
        end
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


    def ensure_filename!
        if self.filename.nil?
            calc_ext = AlaveteliFileTypes.mimetype_to_extension(self.content_type)
            if !calc_ext
                calc_ext = "bin"
            end
            if !self.within_rfc822_subject.nil?
                computed = self.within_rfc822_subject + "." + calc_ext
            else
                computed = "attachment." + calc_ext
            end
            self.filename = computed
        end
    end

    def filename=(filename)
        calc_ext = AlaveteliFileTypes.mimetype_to_extension(self.content_type)
        # Put right extension on if missing
        if !filename.nil? && !filename.match(/\.#{calc_ext}$/) && calc_ext
            computed = filename + "." + calc_ext
        else
            computed = filename
        end
        write_attribute('filename', computed)
    end

    # Size to show next to the download link for the attachment
    def update_display_size!
        s = self.body.size

        if s > 1024 * 1024
            self.display_size = sprintf("%.1f", s.to_f / 1024 / 1024) + 'M'
        else
            self.display_size = (s / 1024).to_s + 'K'
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
                html = AlaveteliExternalCommand.run("pdftohtml", "-nodrm", "-zoom", "1.0", "-stdout", "-enc", "UTF-8", "-noframes", tempfile.path)
            elsif self.content_type == 'application/rtf'
                html = AlaveteliExternalCommand.run("unrtf", "--html", tempfile.path)
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
        if html.size == 0 || !$?.success? || (body_without_tags.size == 0 && !contains_images)
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

