module AlaveteliTextMasker
    extend self
    DoNotBinaryMask = [ 'image/tiff',
                        'image/gif',
                        'image/jpeg',
                        'image/png',
                        'image/bmp',
                        'application/zip' ]

    # Replaces all email addresses in (possibly binary) data
    # Also applies custom masks and censor items
    def apply_masks!(text, content_type, options = {})
        # See if content type is one that we mask - things like zip files and
        # images may get broken if we try to. We err on the side of masking too
        # much, as many unknown types will really be text.

        # Special cases for some content types
        case content_type
            when *DoNotBinaryMask
                # do nothing
            when 'text/html'
                apply_text_masks!(text, options)
            when 'application/pdf'
                apply_pdf_masks!(text, options)
            else
                apply_binary_masks!(text, options)
        end
    end

    def apply_pdf_masks!(text, options = {})
        uncompressed_text = uncompress_pdf(text)
        # if we managed to uncompress the PDF...
        if !uncompressed_text.blank?
            # then censor stuff (making a copy so can compare again in a bit)
            censored_uncompressed_text = uncompressed_text.dup
            apply_binary_masks!(censored_uncompressed_text, options)
            # if the censor rule removed something...
            if censored_uncompressed_text != uncompressed_text
                # then use the altered file (recompressed)
                recompressed_text = compress_pdf(censored_uncompressed_text)
                if recompressed_text.blank?
                    # buggy versions of pdftk sometimes fail on
                    # compression, I don't see it's a disaster in
                    # these cases to save an uncompressed version?
                    recompressed_text = censored_uncompressed_text
                    Rails.logger.warn "Unable to compress PDF; problem with your pdftk version?"
                end
                if !recompressed_text.blank?
                    text.replace recompressed_text
                end
            end
        end
    end

    private

    def uncompress_pdf(text)
        AlaveteliExternalCommand.run("pdftk", "-", "output", "-", "uncompress", :stdin_string => text)
    end

    def compress_pdf(text)
        if AlaveteliConfiguration::use_ghostscript_compression
            command = ["gs",
                       "-sDEVICE=pdfwrite",
                       "-dCompatibilityLevel=1.4",
                       "-dPDFSETTINGS=/screen",
                       "-dNOPAUSE",
                       "-dQUIET",
                       "-dBATCH",
                       "-sOutputFile=-",
                       "-"]
        else
            command = ["pdftk", "-", "output", "-", "compress"]
        end
        AlaveteliExternalCommand.run(*(command + [ :stdin_string => text ]))
    end

    # Replace text in place
    def apply_binary_masks!(text, options = {})
        # Keep original size, so can check haven't resized it
        orig_size = text.mb_chars.size

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
        if String.method_defined?(:encode)
            emails.map! do |email|
                # We want the ASCII representation of UCS-2
                [email[0].encode('UTF-16LE').force_encoding('US-ASCII'),
                 email[0].gsub(/[^@.]/, 'x').encode('UTF-16LE').force_encoding('US-ASCII')]
            end
        else
            emails.map! {|email| [
                    Iconv.conv('ucs-2le', 'ascii', email[0]),
                    Iconv.conv('ucs-2le', 'ascii', email[0].gsub(/[^@.]/, 'x'))
            ] }
        end

        # Now search and replace the UCS-2 email with the UCS-2 mask
        for email, mask in emails
            text.gsub!(email, mask)
        end

        # Replace censor items
        censor_rules = options[:censor_rules] || []
        censor_rules.each{ |censor_rule| censor_rule.apply_to_binary!(text) }
        raise "internal error in apply_binary_masks!" if text.mb_chars.size != orig_size
        return text
    end

    # Remove any email addresses, login links and mobile phone numbers
    def default_text_masks
        [{ :to_replace => MySociety::Validate.email_find_regexp,
           :replacement => "[#{_("email address")}]" },
         { :to_replace => /(Mobile|Mob)([\s\/]*(Fax|Tel))*\s*:?[\s\d]*\d/,
           :replacement => "[#{_("mobile number")}]" },
         { :to_replace => /https?:\/\/#{AlaveteliConfiguration::domain}\/c\/[^\s]+/,
           :replacement => "[#{_("{{site_name}} login link",
                                 :site_name => AlaveteliConfiguration::site_name)}]" }]
    end

    def apply_text_masks!(text, options = {})
        masks = options[:masks] || []
        masks += default_text_masks
        censor_rules = options[:censor_rules] || []
        masks.each{ |mask| text.gsub!(mask[:to_replace], mask[:replacement]) }
        censor_rules.each{ |censor_rule| censor_rule.apply_to_text!(text) }
        text
    end

end
