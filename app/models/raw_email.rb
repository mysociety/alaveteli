# == Schema Information
# Schema version: 73
#
# Table name: raw_emails
#
#  id   :integer         not null, primary key
#  data :text            not null
#

# models/raw_email.rb:
# The fat part of models/incoming_message.rb
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: raw_email.rb,v 1.8 2009-03-09 01:17:06 francis Exp $

class RawEmail < ActiveRecord::Base
    # deliberately don't strip_attributes, so keeps raw email properly
    
    has_one :incoming_message
end


