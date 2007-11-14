# app/models/rejection_reasons.rb
# Give one reason under the Freedom of Information Act 2000 as to why 
# a particular incoming message was rejected. An incoming message can
# have multiple such reasons.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: rejection_reason.rb,v 1.1 2007-11-14 01:01:39 francis Exp $

class RejectionReason < ActiveRecord::Base
    belongs_to :incoming_message
    validates_presence_of :incoming_message_id

    def self.all_reasons
        ['commerciallyconfidential']
    end

    validates_inclusion_of :reason, :in => RejectionReason.all_reasons
end
