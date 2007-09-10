# models/info_request.rb:
# A Freedom of Information request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: info_request.rb,v 1.4 2007-09-10 18:58:43 francis Exp $

class InfoRequest < ActiveRecord::Base
    belongs_to :user
    belongs_to :public_body
    has_many :outgoing_message

#    validates_presence_of :user
#    validates_numericality_of :user
    validates_presence_of :title
    validates_presence_of :public_body_id

end

