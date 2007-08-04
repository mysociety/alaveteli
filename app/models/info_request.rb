# models/info_request.rb:
# A Freedom of Information request.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: info_request.rb,v 1.1 2007-08-04 11:10:26 francis Exp $

class InfoRequest < ActiveRecord::Base
    belongs_to :user

end

