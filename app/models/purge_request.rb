# == Schema Information
#
# Table name: purge_requests
#
#  id         :integer          not null, primary key
#  url        :string(255)
#  created_at :datetime         not null
#  model      :string(255)      not null
#  model_id   :integer          not null
#

# models/purge_request.rb:
# A queue of URLs to purge
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/
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
                sleep_seconds = 30 if sleep_seconds > 30
            end
        end
    end

    def purge
        config = MySociety::Config.load_default()
        varnish_url = config['VARNISH_HOST']
        result = quietly_try_to_purge(varnish_url, self.url)
        self.delete()
    end
end




