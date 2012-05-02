# models/purge_request.rb:
# A queue of URLs to purge
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#

class PurgeRequest < ActiveRecord::Base
    def self.purge_all
        done_something = false
        for item in PurgeRequest.all()
            item.purge
            done_something = true
        end
        return done_something
    end

    def self.purge_all_loop
        # Run purge_all in an endless loop, sleeping when there is nothing to do
        while true
            sleep_seconds = 1
            while !purge_all
                sleep sleep_seconds
                sleep_seconds *= 2
                sleep_seconds = 300 if sleep_seconds > 300
            end
        end
    end

    def purge
        config = MySociety::Config.load_default()
        varnish_url = config['VARNISH_HOST']
        result = quietly_try_to_purge(varnish_url, self.url)
        if result == "200"
            self.delete()
        end
    end
end



