# models/info_request.rb:
# A Freedom of Information request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: info_request.rb,v 1.5 2007-09-11 15:23:59 francis Exp $

class InfoRequest < ActiveRecord::Base
    validates_presence_of :title

    belongs_to :user
#    validates_presence_of :user_id

    belongs_to :public_body
    validates_presence_of :public_body_id

    has_many :outgoing_message
end

