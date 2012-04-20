# models/purge_request.rb:
# A queue of URLs to purge
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#

class PurgeRequest < ActiveRecord::Base
    require 'open-uri'
    def self.purge_all
        for item in PurgeRequest.all()
            item.purge
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



