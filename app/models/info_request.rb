# models/info_request.rb:
# A Freedom of Information request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: info_request.rb,v 1.3 2007-09-10 01:16:35 francis Exp $

class InfoRequest < ActiveRecord::Base
    belongs_to :user
    belongs_to :public_body

#    validates_presence_of :user
#    validates_numericality_of :user
    validates_presence_of :title
    validates_presence_of :public_body_id

end

