# models/info_request.rb:
# A Freedom of Information request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: info_request.rb,v 1.2 2007-08-21 11:33:45 francis Exp $

class InfoRequest < ActiveRecord::Base
    belongs_to :user

#    validates_presence_of :user
#    validates_numericality_of :user
    validates_presence_of :title
end

