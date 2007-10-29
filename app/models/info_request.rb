# models/info_request.rb:
# A Freedom of Information request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: info_request.rb,v 1.8 2007-10-29 18:11:34 francis Exp $

require 'digest/sha1'

class InfoRequest < ActiveRecord::Base
    validates_presence_of :title

    belongs_to :user
    validates_presence_of :user_id

    belongs_to :public_body
    validates_presence_of :public_body_id

    has_many :outgoing_messages
    has_many :incoming_messages

    # Email which public body should use to respond to request. This is in
    # the format PREFIXrequest-ID-HASH@DOMAIN. Here ID is the id of the 
    # FOI request, and HASH is a signature for that id.
    def incoming_email
        incoming_email = MySociety::Config.get("INCOMING_EMAIL_PREFIX", "") 
        incoming_email += "request-" + self.id.to_s 
        incoming_email += "-" + Digest::SHA1.hexdigest(self.id.to_s + MySociety::Config.get("INCOMING_EMAIL_SECRET"))[0,8]
        incoming_email += "@" + MySociety::Config.get("INCOMING_EMAIL_DOMAIN", "localhost")
        return incoming_email
    end

    # Return info request corresponding to an incoming email address, or nil if
    # none found. Checks the hash to ensure the email came from the public body -
    # only they are sent the email address with the has in it.
    def self.find_by_incoming_email(incoming_email)
        incoming_email =~ /request-(\d+)-([a-z0-9]+)/
        id = $1.to_i
        hash = $2

        expected_hash = Digest::SHA1.hexdigest(id.to_s + MySociety::Config.get("INCOMING_EMAIL_SECRET"))[0,8]
        #print "expected: " + expected_hash + "\nhash: " + hash + "\n"
        if hash != expected_hash
            return nil
        else
            return self.find(id)
        end
    end

    # A new incoming email to this request
    def receive(email, raw_email)
        incoming_message = IncomingMessage.new
        incoming_message.raw_data = raw_email
        incoming_message.info_request = self
        incoming_message.save
    end

end


