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

# On Ruby versions before 2.0, we needed to use the net-http-local gem
# to force the use of 127.0.0.1 as the local interface for the
# connection.  However, at the time of writing this gem doesn't work
# on Ruby 2.0 and it's not necessary with that Ruby version - one can
# supply a :local_host option to Net::HTTP:start.  So, this helper
# function is to abstract away that difference, and can be used as you
# would Net::HTTP.start(host) when passed a block.
def http_from_localhost(host)
  Net::HTTP.bind '127.0.0.1' do
    Net::HTTP.start(host) do |http|
      yield http
    end
  end
end
