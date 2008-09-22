# == Schema Information
# Schema version: 67
#
# Table name: raw_emails
#
#  id   :integer         not null, primary key
#  data :text            
#

# models/raw_email.rb:
# The fat part of models/incoming_message.rb
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: raw_email.rb,v 1.2 2008-09-22 22:16:37 francis Exp $

class RawEmail < ActiveRecord::Base
    has_one :incoming_message
end


