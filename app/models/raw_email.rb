# models/raw_email.rb:
# The fat part of models/incoming_message.rb
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: raw_email.rb,v 1.1 2008-09-22 22:08:44 francis Exp $

class RawEmail < ActiveRecord::Base
    has_one :incoming_message
end


