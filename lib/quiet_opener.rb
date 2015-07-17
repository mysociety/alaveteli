# -*- encoding : utf-8 -*-
require 'open-uri'
require 'net-purge'
if RUBY_VERSION.to_f < 2.0
  require 'net/http/local'
end

def quietly_try_to_open(url)
  begin
    result = open(url).read.strip
  rescue OpenURI::HTTPError,
      SocketError,
      Errno::ETIMEDOUT,
      Errno::ECONNREFUSED,
      Errno::EHOSTUNREACH,
      Errno::ECONNRESET,
      Timeout::Error => exception
    e = Exception.new("Unable to open third-party URL #{url}: #{exception.message}")
    e.set_backtrace(exception.backtrace)
    if !AlaveteliConfiguration.exception_notifications_from.blank? && !AlaveteliConfiguration.exception_notifications_to.blank?
      ExceptionNotifier::Notifier.exception_notification(request.env, e).deliver
    end
    Rails.logger.warn(e.message)
    result = ""
  end
  return result
end

# On Ruby versions before 2.0, we need to use the net-http-local gem
# to force the use of 127.0.0.1 as the local interface for the
# connection.  However, at the time of writing this gem doesn't work
# on Ruby 2.0 and it's not necessary with that Ruby version - one can
# supply a :local_host option to Net::HTTP:start.  So, this helper
# function is to abstract away that difference, and can be used as you
# would Net::HTTP.start(host) when passed a block.
def http_from_localhost(host)
  if RUBY_VERSION.to_f >= 2.0
    Net::HTTP.start(host, :local_host => '127.0.0.1') do |http|
      yield http
    end
  else
    Net::HTTP.bind '127.0.0.1' do
      Net::HTTP.start(host) do |http|
        yield http
      end
    end
  end
end

def quietly_try_to_purge(host, url)
  begin
    result = ""
    result_body = ""
    http_from_localhost(host) do |http|
      request = Net::HTTP::Purge.new(url)
      response = http.request(request)
      result = response.code
      result_body = response.body
    end
  rescue OpenURI::HTTPError, SocketError, Errno::ETIMEDOUT, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ECONNRESET, Errno::ENETUNREACH
    Rails.logger.warn("PURGE: Unable to reach host #{host}")
  end
  if result == "200"
    Rails.logger.debug("PURGE: Purged URL #{url} at #{host}: #{result}")
  else
    Rails.logger.warn("PURGE: Unable to purge URL #{url} at #{host}: status #{result}")
  end
  return result
end
