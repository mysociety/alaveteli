# Monkey patch for CVE-2013-4389
# derived from http://seclists.org/oss-sec/2013/q4/118 to fix
# a possible DoS vulnerability in the log subscriber component of
# Action Mailer.

require 'action_mailer'
module ActionMailer
  class LogSubscriber < ActiveSupport::LogSubscriber
    def deliver(event)
      recipients = Array.wrap(event.payload[:to]).join(', ')
      info("\nSent mail to #{recipients} (#{event.duration.round(1)}ms)")
      debug(event.payload[:mail])
    end
  end
end
