require 'net/http'

##
# Raised by fetch_url! when a URL can't be fetched. Holds the response when
# the server replied with an error status.
#
class FetchURLError < StandardError
  attr_reader :response

  def initialize(message, response: nil)
    super(message)
    @response = response
  end
end

##
# Fetch the body of a URL. Logs a warning and returns an empty string if it
# can't be fetched.
#
def fetch_url(url, timeout: 60)
  begin
    result = fetch_url!(url, timeout: timeout).strip
  rescue FetchURLError => exception
    e = FetchURLError.new(
      "Unable to open third-party URL #{url}: #{exception.message}",
      response: exception.response
    )
    e.set_backtrace(exception.backtrace)
    # Send a notification if in a request context
    if !AlaveteliConfiguration.exception_notifications_from.blank? &&
       !AlaveteliConfiguration.exception_notifications_to.blank? &&
       defined?(request)
      ExceptionNotifier.notify_exception(e, env: request.env)
    end
    Rails.logger.warn(e.message)
    result = ""
  end
  result
end

def quietly_try_to_open(url, timeout = 60)
  warn %q([DEPRECATION] quietly_try_to_open will be removed in 0.48. It has
          been replaced by fetch_url).squish
  fetch_url(url, timeout: timeout)
end

##
# Fetch the body of a URL, raising FetchURLError if it can't be fetched.
#
# Unlike URI.open, only fetches HTTP(S) URLs, so a URL can't read a local
# file or run a command.
#
def fetch_url!(url, timeout: 60, redirects: 5)
  uri = URI.parse(url.to_s)
  unless uri.is_a?(URI::HTTP) && uri.host.present?
    raise FetchURLError, "Unsupported URL #{url}"
  end

  response = Net::HTTP.start(
    uri.hostname, uri.port,
    use_ssl: uri.is_a?(URI::HTTPS), read_timeout: timeout
  ) do |http|
    http.response_body_encoding = true
    http.request(Net::HTTP::Get.new(uri))
  end

  case response
  when Net::HTTPSuccess
    body = response.body.to_s
    # Match open-uri, which reads text without a charset as UTF-8
    if body.encoding == Encoding::BINARY && response.main_type == 'text'
      body.force_encoding(Encoding::UTF_8)
    end
    body
  when Net::HTTPRedirection
    raise FetchURLError, "Too many redirects for #{url}" if redirects.zero?

    location = response['location']
    if location.blank?
      raise FetchURLError.new(
        "#{response.code} #{response.message}", response: response
      )
    end

    target = URI.join(uri, location)
    if uri.is_a?(URI::HTTPS) && !target.is_a?(URI::HTTPS)
      raise FetchURLError, "Refused redirect from HTTPS to #{target}"
    end

    fetch_url!(target, timeout: timeout, redirects: redirects - 1)
  else
    raise FetchURLError.new(
      "#{response.code} #{response.message}", response: response
    )
  end

rescue URI::Error, SocketError, SystemCallError, IOError, Timeout::Error,
       OpenSSL::SSL::SSLError, Net::ProtocolError, Net::HTTPBadResponse => e
  raise FetchURLError, e.message
end
