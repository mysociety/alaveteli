# -*- encoding : utf-8 -*-
# Handles filtering email replies

module MailHandler
  module ReplyHandler
    def self.permanently_failed_addresses(message)
      if MailHandler.empty_return_path?(message)
        # Some sort of auto-response

        # Check for Exim’s X-Failed-Recipients header
        failed_recipients = MailHandler.get_header_string("X-Failed-Recipients", message)
        if !failed_recipients.nil?
          # The X-Failed-Recipients header contains the email address that failed
          # Check for the words "This is a permanent error." in the body, to indicate
          # a permanent failure
          if MailHandler.get_part_body(message) =~ /This is a permanent error./
            return failed_recipients.split(/,\s*/)
          end
        end

        # Next, look for multipart/report
        if MailHandler.get_content_type(message) == "multipart/report"
          permanently_failed_recipients = []
          message.parts.each do |part|
            if MailHandler.get_content_type(part) == "message/delivery-status"
              sections = MailHandler.get_part_body(part).split(/\r?\n\r?\n/)
              # The first section is a generic header; subsequent sections
              # represent a particular recipient. Since we
              sections[1..-1].each do |section|
                if section !~ /^Status: (\d)/ || $1 != '5'
                  # Either we couldn’t find the Status field, or it was a transient failure
                  break
                end
                if section =~ /^Final-Recipient: rfc822;(.+)/
                  permanently_failed_recipients.push($1)
                end
              end
            end
          end
          if !permanently_failed_recipients.empty?
            return permanently_failed_recipients
          end
        end
      end

      subject = MailHandler.get_header_string("Subject", message)
      # Then look for the style we’ve seen in WebShield bounces
      # (These do not have a return path of <> in the cases I have seen.)
      if subject == "Returned Mail: Error During Delivery"
        if MailHandler.get_part_body(message) =~ /^\s*---- Failed Recipients ----\s*((?:<[^>]+>\n)+)/
          return $1.scan(/<([^>]+)>/).flatten
        end
      end

      return []
    end

    def self.is_oof?(message)
      # Check for out-of-office

      if MailHandler.get_header_string("X-POST-MessageClass", message) == "9; Autoresponder"
        return true
      end

      subject = MailHandler.get_header_string("Subject", message).downcase
      if MailHandler.empty_return_path?(message)
        if subject.start_with? "out of office: "
          return true
        end
        if subject.start_with? "automatic reply: "
          return true
        end
      end

      if MailHandler.get_header_string("Auto-Submitted", message) == "auto-generated"
        if subject =~ /out of( the)? office/
          return true
        end
      end

      if subject.start_with? "out of office autoreply:"
        return true
      end
      if subject == "out of office"
        return true
      end
      if subject == "out of office reply"
        return true
      end
      if subject.end_with? "is out of the office"
        return true
      end
      return false
    end

    def self.forward_on(raw_message, message = nil)
      forward_to = self.get_forward_to_address(message)
      IO.popen("/usr/sbin/sendmail -i #{forward_to}", "wb") do |f|
        f.write(raw_message);
        f.close;
      end
    end

    def self.get_forward_to_address(message)
      forward_to = AlaveteliConfiguration.forward_nonbounce_responses_to
      if AlaveteliConfiguration.enable_alaveteli_pro
        pro_contact_email = AlaveteliConfiguration.pro_contact_email
        original_to = message ? MailHandler.get_all_addresses(message) : []
        if original_to.include?(pro_contact_email)
          forward_to = AlaveteliConfiguration.forward_pro_nonbounce_responses_to
        end
      end
      forward_to
    end

    def self.load_rails
      require File.join($alaveteli_dir, 'config', 'boot')
      require File.join($alaveteli_dir, 'config', 'environment')
    end

    def self.record_bounce(email_address, bounce_message)
      self.load_rails
      User.record_bounce_for_email(email_address, bounce_message)
    end
  end
end
