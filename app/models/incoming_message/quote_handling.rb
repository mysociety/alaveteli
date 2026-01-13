# Various email quoted section handling for `IncomingMessage` records
module IncomingMessage::QuoteHandling
  extend ActiveSupport::Concern

  class_methods do
    # Remove quoted sections from emails (eventually the aim would be for this
    # to do as good a job as GMail does) TODO: bet it needs a proper parser
    # TODO: and this FOLDED_QUOTED_SECTION stuff is a mess
    def remove_quoted_sections(text, replacement = "FOLDED_QUOTED_SECTION")
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
      multiline_original_message = '(>>>.* \d\d/\d\d/\d\d\d\d\s+\d\d:\d\d(?::\d\d)?\s*>>>)'
      text.gsub!(/^(#{multiline_original_message}\n.*)$/m, replacement)

      # On Thu, Nov 28, 2013 at 9:08 AM, A User
      # <[1]request-7-skm40s2ls@xxx.xxxx> wrote:
      text.gsub!(/^( On [^\n]+\n\s*\<[^>\n]+\> (wrote|said):\s*\n.*)$/m, replacement)

      # Single line sections
      text.gsub!(/^(>.*\n)/, replacement)
      text.gsub!(/^(On .+ (wrote|said):\n)/, replacement)

      ['-', '_', '*', '#'].each do |scorechar|
        score = /(?:[#{scorechar}]\s*){8,}/
        text.sub!(/(Disclaimer\s+)?  # appears just before
                          (
                              \s*#{score}\n(?:(?!#{score}\n).)*? # top line
                              (disclaimer:\n|confidential|received\sthis\semail\sin\serror|virus|intended\s+recipient|monitored\s+centrally|intended\s+(for\s+|only\s+for\s+use\s+by\s+)the\s+addressee|routinely\s+monitored|MessageLabs|unauthorised\s+use)
                              .*?(?:#{score}|\z) # bottom line OR end of whole string (for ones with no terminator TODO: risky)
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
      message_section_strings = [
        '----* This is a copy of the message, including all the headers. ----*',
        '----*\s*Original Message\s*----*',
        '----*\s*Forwarded message.+----*',
        '----*\s*Forwarded by.+----*'
      ]
      original_message = "(#{message_section_strings.join('|')})"
      # Could have a ^ at start here, but see messed up formatting here:
      # http://www.whatdotheyknow.com/request/refuse_and_recycling_collection#incoming-842
      text.gsub!(/(#{original_message}\n.*)$/mi, replacement)

      # Some silly Microsoft XML gets into parts marked as plain text.
      # e.g. http://www.whatdotheyknow.com/request/are_traffic_wardens_paid_commiss#incoming-401
      # Don't replace with "replacement" as it's pretty messy
      text.gsub(/<\?xml:namespace[^>]*\/>/, " ")
    end
  end

  # Lotus notes quoting yeuch!
  def remove_lotus_quoting(text, replacement = "FOLDED_QUOTED_SECTION")
    text = text.dup
    return text if info_request.user_name.nil?

    name = Regexp.escape(info_request.user_name)

    # To end of message sections
    text.gsub!(/^\s?#{name}[^\n]+\n([^\n]+\n)?\s?Sent by:[^\n]+\n.*/im, "\n\n" + replacement)

    # Some other sort of forwarding quoting
    text.gsub!(/^\s?#{name}\s+To\s+FOI requests at.*/im, "\n\n" + replacement)

    # http://www.whatdotheyknow.com/request/229/response/809
    text.gsub(/^\s?From: [^\n]+\n\s?Sent: [^\n]+\n\s?To:\s+['"]?#{name}['"]?\n\s?Subject:.*/im, "\n\n" + replacement)
  end

  private

  def handle_quoted_sections(text, collapse: true)
    if collapse
      text = text.gsub(/(\s*FOLDED_QUOTED_SECTION\s*)+/m, "FOLDED_QUOTED_SECTION")
      text = text.strip

      # if there is nothing but quoted stuff, then show the subject
      if text == "FOLDED_QUOTED_SECTION"
        text = "[Subject only] " + CGI.escapeHTML(subject || '') + text
      end

      # and display link for quoted stuff
      text = text.gsub(/FOLDED_QUOTED_SECTION/, "\n\n" + '<span class="unfold_link"><a href="?unfold=1#incoming-'+id.to_s+'">'+_("show quoted sections")+'</a></span>' + "\n\n")
    elsif get_main_body_text_folded.include?('FOLDED_QUOTED_SECTION')
      text = text + "\n\n" + '<span class="unfold_link"><a href="?#incoming-'+id.to_s+'">'+_("hide quoted sections")+'</a></span>'
    end

    text.strip
  end
end
