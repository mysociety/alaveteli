# == Schema Information
# Schema version: 68
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
# $Id: raw_email.rb,v 1.3 2008-10-28 13:04:20 francis Exp $

class RawEmail < ActiveRecord::Base
    has_one :incoming_message
end


