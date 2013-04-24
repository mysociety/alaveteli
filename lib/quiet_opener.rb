require 'open-uri'
require 'net-purge'
require 'net/http/local'

def quietly_try_to_open(url)
    begin
        result = open(url).read.strip
    rescue OpenURI::HTTPError, SocketError, Errno::ETIMEDOUT, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ECONNRESET
        Rails.logger.warn("Unable to open third-party URL #{url}")
        result = ""
    end
    return result
end

def quietly_try_to_purge(host, url)
    begin
        result = ""
        result_body = ""
        Net::HTTP.bind '127.0.0.1' do
            Net::HTTP.start(host) {|http|
                request = Net::HTTP::Purge.new(url)
                response = http.request(request)
                result = response.code
                result_body = response.body
            }
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

