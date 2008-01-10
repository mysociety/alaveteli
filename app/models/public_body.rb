# == Schema Information
# Schema version: 25
#
# Table name: public_bodies
#
#  id                :integer         not null, primary key
#  name              :text            
#  short_name        :text            
#  request_email     :text            
#  complaint_email   :text            
#  version           :integer         
#  last_edit_editor  :string(255)     
#  last_edit_comment :string(255)     
#  created_at        :datetime        
#  updated_at        :datetime        
#

# models/public_body.rb:
# A public body, from which information can be requested.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: public_body.rb,v 1.13 2008-01-10 01:13:28 francis Exp $

class PublicBody < ActiveRecord::Base
    validates_presence_of :name
    validates_presence_of :short_name
    validates_presence_of :request_email

    has_many :info_requests

    def validate
        unless MySociety::Validate.is_valid_email(self.request_email)
            errors.add(:request_email, "doesn't look like a valid email address")
        end
        if self.complaint_email != ""
            unless MySociety::Validate.is_valid_email(self.complaint_email)
                errors.add(:complaint_email, "doesn't look like a valid email address")
            end
        end
    end

    acts_as_versioned
    self.non_versioned_columns << 'created_at' << 'updated_at'
end
