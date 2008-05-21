# == Schema Information
# Schema version: 56
#
# Table name: public_body_tags
#
#  id             :integer         not null, primary key
#  public_body_id :integer         not null
#  name           :text            not null
#  created_at     :datetime        not null
#

# models/public_body_tag.rb:
# Categories for public bodies.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: public_body_tag.rb,v 1.13 2008-05-21 10:51:24 francis Exp $

class PublicBodyTag < ActiveRecord::Base
    validates_presence_of :public_body
    validates_presence_of :name

    belongs_to :public_body
end

