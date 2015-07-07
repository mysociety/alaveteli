# -*- encoding : utf-8 -*-
require 'digest/sha1'

class AddHashToInfoRequest < ActiveRecord::Migration
    def self.up
        add_column :info_requests, :idhash, :string

        # Create the missing events for requests already sent
        InfoRequest.all.each do |info_request|
            info_request.idhash = Digest::SHA1.hexdigest(info_request.id.to_s + AlaveteliConfiguration::incoming_email_secret)[0,8]
            info_request.save!
        end
        change_column :info_requests, :idhash, :string, :null => false
    end
    def self.down
        remove_column :info_requests, :idhash
    end
end



