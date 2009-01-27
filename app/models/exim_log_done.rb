# models/exim_log_done.rb:
# Stores that a particular exim file has been loaded in, see exim_log.rb
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: exim_log_done.rb,v 1.1 2009-01-27 17:12:31 francis Exp $

class EximLogDone < ActiveRecord::Base
    has_many :exim_logs
end



