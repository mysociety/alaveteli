# -*- encoding : utf-8 -*-
Dir[File.dirname(__FILE__) + '/text_masks/*.rb'].each do |file|
  require file
end

module AlaveteliTextMasker
  extend self
  DoNotBinaryMask = [ 'image/tiff',
                      'image/gif',
                      'image/jpeg',
                      'image/png',
                      'image/bmp',
                      'application/zip' ]

  TextMask = [ 'text/css',
               'text/csv',
               'text/html',
               'text/plain',
               'text/rfc822-headers',
               'text/rtf',
               'text/tab-separated-values',
               'text/x-c',
               'text/x-diff',
               'text/x-fortran',
               'text/x-mail',
               'text/xml',
               'text/x-pascal',
               'text/x-vcard' ]

  # Replaces all email addresses in (possibly binary) data
  # Also applies custom masks and censor items
  def apply_masks(text, content_type, options = {})
    # See if content type is one that we mask - things like zip files and
    # images may get broken if we try to. We err on the side of masking too
    # much, as many unknown types will really be text.

    # Special cases for some content types
    case content_type
    when *DoNotBinaryMask
      text # do nothing
    when *TextMask
      apply_text_masks(text, options)
    when 'application/pdf'
      apply_pdf_masks(text, options)
    else
      apply_binary_masks(text, options)
    end
  end

  # Replaces all email addresses in (possibly binary) data
  # Also applies custom masks and censor items
  def apply_masks!(text, content_type, options = {})
    warn %q([DEPRECATION] AlaveteliTextMasker#apply_masks! will be removed
            in 0.24. Use the non-destructive AlaveteliTextMasker#apply_masks
            instead).squish
    # See if content type is one that we mask - things like zip files and
    # images may get broken if we try to. We err on the side of masking too
    # much, as many unknown types will really be text.

    # Special cases for some content types
    case content_type
    when *DoNotBinaryMask
      # do nothing
    when *TextMask
      apply_text_masks!(text, options)
    when 'application/pdf'
      apply_pdf_masks!(text, options)
    else
      apply_binary_masks!(text, options)
    end
  end

  def apply_pdf_masks!(text, options = {})
    warn %q([DEPRECATION] AlaveteliTextMasker#apply_pdf_masks! will be removed
            in 0.24. Use AlaveteliTextMasker.apply_masks, which will implement
            a private AlaveteliTextMasker.apply_pdf_masks).squish

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

  def apply_pdf_masks(text, options = {})
    uncompressed_text = uncompress_pdf(text)
    # if we managed to uncompress the PDF...
    if uncompressed_text.blank?
      text
    else
      # then censor stuff (making a copy so can compare again in a bit)
      censored_uncompressed_text = apply_binary_masks(uncompressed_text.dup, options)

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

        unless recompressed_text.blank?
          recompressed_text
        end
      end
    end
  end


  def apply_binary_masks(text, options = {})
    # Keep original size, so can check haven't resized it
    orig_size = text.size
    text = text.dup

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
    emails.map! do |email|
      # We want the ASCII representation of UCS-2
      [email[0].encode('UTF-16LE').force_encoding('US-ASCII'),
       email[0].gsub(/[^@.]/, 'x').encode('UTF-16LE').force_encoding('US-ASCII')]
    end

    # Now search and replace the UCS-2 email with the UCS-2 mask
    emails.each do |email, mask|
      text.gsub!(email, mask)
    end

    # Replace censor items
    censor_rules = options[:censor_rules] || []

    # TODO: Add and use CensorRule#apply_to_binary
    censor_rules.each{ |censor_rule| censor_rule.apply_to_binary!(text) }

    raise "internal error in apply_binary_masks" if text.size != orig_size

    text
  end

  # Replace text in place
  def apply_binary_masks!(text, options = {})
    warn %q([DEPRECATION] AlaveteliTextMasker#apply_binary_masks! will be
            removed in 0.24. Use the non-destructive
            AlaveteliTextMasker#apply_binary_masks instead).squish
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
    raise "internal error in apply_binary_masks!" if text.size != orig_size
    return text
  end

  # Remove any email addresses, login links and mobile phone numbers
  def default_text_masks(middleware=false)
    if middleware
      ::Middleware::Builder.new do |m|
        m.use TextMasks::EmailAddressMasker
        m.use TextMasks::RegexpMasker,
              :regexp => /(Mobile|Mob)([\s\/]*(Fax|Tel))*\s*:?[\s\d]*\d/,
              :replacement => "[#{_("mobile number")}]"
        m.use TextMasks::RegexpMasker,
              :regexp => /https?:\/\/#{ AlaveteliConfiguration.domain }\/c\/[^\s]+/,
              :replacement => "[#{_("{{site_name}} login link",
                              :site_name => AlaveteliConfiguration.site_name)}]"
      end
    else
      [{ :to_replace => MySociety::Validate.email_find_regexp,
         :replacement => "[#{_("email address")}]" },
       { :to_replace => /(Mobile|Mob)([\s\/]*(Fax|Tel))*\s*:?[\s\d]*\d/,
         :replacement => "[#{_("mobile number")}]" },
       { :to_replace => /https?:\/\/#{AlaveteliConfiguration::domain}\/c\/[^\s]+/,
         :replacement => "[#{_("{{site_name}} login link",
                               :site_name => AlaveteliConfiguration::site_name)}]" }]
    end
  end

  def apply_text_masks(text, options = {})
    censor_rules = options[:censor_rules] || []

    stack = Middleware::Builder.new do |s|
      s.use options[:masks] if options[:masks]

      # TODO: Temporarily pass true to get the middleware stack rather than
      # the Array of hashes. Remove in [v0.24.0.0]
      s.use default_text_masks(true)

      # TODO: Add censor rules in to stack:
      # s.use options[:censor_rules] if options[:censor_rules]
    end

    text = stack.call(text)

    text = censor_rules.inject(text) do |memo, censor_rule|
      censor_rule.apply_to_text!(memo)
    end
  end

  def apply_text_masks!(text, options = {})
    warn %q([DEPRECATION] AlaveteliTextMasker#apply_text_masks! will be removed
            in 0.24. Use the non-destructive
            AlaveteliTextMasker#apply_text_masks instead).squish
    masks = options[:masks] || []
    masks += default_text_masks
    censor_rules = options[:censor_rules] || []
    masks.each{ |mask| text.gsub!(mask[:to_replace], mask[:replacement]) }
    censor_rules.each{ |censor_rule| censor_rule.apply_to_text!(text) }
    text
  end

end
