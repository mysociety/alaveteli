require 'open-uri'
require 'net-purge'

def quietly_try_to_open(url)
    begin 
        result = open(url).read.strip
    rescue OpenURI::HTTPError, SocketError, Errno::ETIMEDOUT, Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        logger.warn("Unable to open third-party URL #{url}")
        result = ""
    end
    return result
end
    
def quietly_try_to_purge(host, url)
    begin 
        result = ""
        result_body = ""
        Net::HTTP.start(host) {|http|
            request = Net::HTTP::Purge.new(url)
            response = http.request(request)
            result = response.code
            result_body = response.body
        }
    rescue OpenURI::HTTPError, SocketError, Errno::ETIMEDOUT, Errno::ECONNREFUSED, Errno::EHOSTUNREACH
        logger.warn("Unable to reach host #{host}")
    end
    if result == "200"
        logger.info("Purged URL #{url} at #{host}: #{result}")
    else
        logger.warn("Unable to purge URL #{url} at #{host}: status #{result}")
    end
    return result
end
    
