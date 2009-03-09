# == Schema Information
# Schema version: 74
#
# Table name: holidays
#
#  id          :integer         not null, primary key
#  day         :date            
#  description :text            
#

# models/holiday.rb:
# Store details on public holidays on which the clock for answering FOI
# requests do not run
#
# Copyright (c) 2009 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: holiday.rb,v 1.2 2009-03-09 15:48:32 tony Exp $

class Holiday < ActiveRecord::Base
end
