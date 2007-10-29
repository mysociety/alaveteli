# models/incoming_message.rb:
# A message from really anybody to be logged with a request. e.g.
# A response from the public body.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: incoming_message.rb,v 1.1 2007-10-29 18:11:34 francis Exp $

class IncomingMessage < ActiveRecord::Base
    belongs_to :info_request
    validates_presence_of :info_request

    validates_presence_of :raw_data
end


