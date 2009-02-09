# == Schema Information
# Schema version: 71
#
# Table name: exim_log_dones
#
#  id         :integer         not null, primary key
#  filename   :text            not null
#  last_stat  :datetime        not null
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

# models/exim_log_done.rb:
# Stores that a particular exim file has been loaded in, see exim_log.rb
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: exim_log_done.rb,v 1.2 2009-02-09 09:51:53 francis Exp $

class EximLogDone < ActiveRecord::Base
    has_many :exim_logs
end



