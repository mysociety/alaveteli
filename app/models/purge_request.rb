# -*- encoding : utf-8 -*-
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

    PurgeRequest.all.each do |item|
      item.purge
      done_something = true
    end

    done_something
  end

  # Run purge_all in an endless loop, sleeping when there is nothing to do
  def self.purge_all_loop
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
    config = MySociety::Config.load_default
    result = quietly_try_to_purge(config['VARNISH_HOST'], url)
    delete
  end
end
