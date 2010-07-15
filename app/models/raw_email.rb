# == Schema Information
# Schema version: 84
#
# Table name: raw_emails
#
#  id          :integer         not null, primary key
#  data_text   :text            
#  data_binary :binary          
#

# models/raw_email.rb:
# The fat part of models/incoming_message.rb
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: raw_email.rb,v 1.12 2009-09-17 21:10:05 francis Exp $

class RawEmail < ActiveRecord::Base
    # deliberately don't strip_attributes, so keeps raw email properly
    
    has_one :incoming_message


    # We keep the old data_text field (which is of type text) for backwards
    # compatibility. We use the new data_binary field because only it works
    # properly in recent versions of PostgreSQL (get seg faults escaping
    # some binary strings).

    def data=(d)
        write_attribute(:data_binary, d)
    end

    def data
        d = read_attribute(:data_binary)
        if !d.nil?
            return d
        end

        d = read_attribute(:data_text)
        if !d.nil?
            return d
        end

        raise "internal error, double nil value in RawEmail"
    end

end


