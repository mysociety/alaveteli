require 'digest/sha1'

class AddHashToInfoRequest < ActiveRecord::Migration
    def self.up
        add_column :info_requests, :idhash, :string

        # Create the missing events for requests already sent
        InfoRequest.find(:all).each do |info_request|
            info_request.idhash = Digest::SHA1.hexdigest(info_request.id.to_s + Configuration::incoming_email_secret)[0,8]
            info_request.save!
            puts info_request.idhash
        end
        change_column :info_requests, :idhash, :string, :null => false
        puts InfoRequest.find_by_idhash
    end
    def self.down
        remove_column :info_requests, :idhash
    end
end



