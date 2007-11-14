# models/info_request.rb:
# A Freedom of Information request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: info_request.rb,v 1.13 2007-11-14 01:01:39 francis Exp $

require 'digest/sha1'

class InfoRequest < ActiveRecord::Base
    validates_presence_of :title, :message => "^Please enter a summary of your request"

    belongs_to :user
    #validates_presence_of :user_id # breaks during construction of new ones :(

    belongs_to :public_body
    validates_presence_of :public_body_id

    has_many :outgoing_messages
    has_many :incoming_messages

    # Email which public body should use to respond to request. This is in
    # the format PREFIXrequest-ID-HASH@DOMAIN. Here ID is the id of the 
    # FOI request, and HASH is a signature for that id.
    def incoming_email
        raise "id required to make incoming_email" if not self.id
        incoming_email = MySociety::Config.get("INCOMING_EMAIL_PREFIX", "") 
        incoming_email += "request-" + self.id.to_s 
        incoming_email += "-" + Digest::SHA1.hexdigest(self.id.to_s + MySociety::Config.get("INCOMING_EMAIL_SECRET", 'dummysecret'))[0,8]
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

        expected_hash = Digest::SHA1.hexdigest(id.to_s + MySociety::Config.get("INCOMING_EMAIL_SECRET", 'dummysecret'))[0,8]
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

    # Work out what the situation of the request is
    def calculate_status
        # Extract aggregate information for any incoming messages all together
        contains_information = false
        rejection_reasons = []
        self.incoming_messages.each do |msg|
            if msg.user_classified
                if msg.contains_information
                    contains_information = true
                end
                rejection_reasons += msg.rejection_reasons
            end
        end

        # See if response would be overdue 
        overdue = false
        # XXX if a second outgoing message is really a new request, then this
        # is no good
        earliest_sent = self.outgoing_messages.map { |om| om.sent_at }.min
        time_left = Time.now - earliest_sent
        # XXX use working days 
        if time_left > 20.days
            overdue = true
        end

        # Return appropriate status string
        if self.incoming_messages.size == 0
            if overdue
                return "overdue"
            else
                return "awaiting"
            end
        end
        if contains_information and rejection_reasons.size > 0
            return "information_and_rejection"
        end
        if contains_information and rejection_reasons.size == 0
            return "information"
        end
        if rejection_reasons.size > 0 
            return "rejection"
        end
        return "unknown"
    end
    # - Awaiting response (in 20 working day limit)
    # - Overdue a response (over 20 working day limit)
    #
    # - Has a response but not sure what to think of it
    # - Received a positive response
    # - Received a partly positive response w/ rejection reasons
    # - Received an entirely negative response w/ rejection reasons
    #
    # - Have sent a follow up

end


