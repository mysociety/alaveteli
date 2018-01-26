# -*- encoding : utf-8 -*-
require 'open-uri'

def quietly_try_to_open(url, timeout=60)
  begin
    result = open(url, :read_timeout => timeout).read.strip
  rescue OpenURI::HTTPError,
         SocketError,
         Errno::ETIMEDOUT,
         Errno::ECONNREFUSED,
         Errno::EHOSTDOWN,
         Errno::ENETUNREACH,
         Errno::EHOSTUNREACH,
         Errno::ECONNRESET,
         Timeout::Error => exception
    e = Exception.new("Unable to open third-party URL #{url}: #{exception.message}")
    e.set_backtrace(exception.backtrace)
    # Send a notification if in a request context
    if !AlaveteliConfiguration.exception_notifications_from.blank? &&
       !AlaveteliConfiguration.exception_notifications_to.blank? &&
       defined?(request)
      ExceptionNotifier.notify_exception(e, :env => request.env)
    end
    Rails.logger.warn(e.message)
    result = ""
  end
  return result
end
