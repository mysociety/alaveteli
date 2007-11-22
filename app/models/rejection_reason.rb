# app/models/rejection_reasons.rb
# Give one reason under the Freedom of Information Act 2000 as to why 
# a particular incoming message was rejected. An incoming message can
# have multiple such reasons.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: rejection_reason.rb,v 1.2 2007-11-22 15:22:36 francis Exp $

class RejectionReason < ActiveRecord::Base
    belongs_to :incoming_message
    validates_presence_of :incoming_message_id

    @@all_reasons = [
            { "section21" => "Information accessible to applicant by other means" },
            { "section22" => "Information intended for future publication" },
            { "section23" => "Information supplied by, or relating to, bodies dealing with security matters" },
            { "section24" => "National security" },
            { "section25" => "Certificates under ss. 23 and 24: supplementary provisions" },
            { "section26" => "Defence" },
            { "section27" => "International relations" },
            { "section28" => "Relations within the United Kingdom" },
            { "section29" => "The economy" },
            { "section30" => "Investigations and proceedings conducted by public authorities" },
            { "section31" => "Law enforcement" },
            { "section32" => "Court records, etc" },
            { "section33" => "Audit functions" },
            { "section34" => "Parliamentary privilege" },
            { "section35" => "Formulation of government policy, etc" },
            { "section36" => "Prejudice to effective conduct of public affairs" },
            { "section37" => "Communications with Her Majesty, etc. and honours" },
            { "section38" => "Health and safety" },
            { "section39" => "Environmental information" },
            { "section40" => "Personal information" },
            { "section41" => "Information provided in confidence" },
            { "section42" => "Legal professional privilege" },
            { "section43" => "Commercial interests" },
            { "section44" => "Prohibitions on disclosure" }
        ]
    @@all_reasons_array = @@all_reasons.map{ |h| h.keys }.flatten
    @@all_reasons_hash = {}
    @@all_reasons.each { |h| @@all_reasons_hash.merge!(h) }

   cattr_accessor :all_reasons_array
   cattr_accessor :all_reasons_hash

#    validates_inclusion_of :reason, :in => RejectionReason.all_reasons_array
end

