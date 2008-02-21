# == Schema Information
# Schema version: 32
#
# Table name: public_bodies
#
#  id                :integer         not null, primary key
#  name              :text            not null
#  short_name        :text            not null
#  request_email     :text            not null
#  complaint_email   :text            
#  version           :integer         not null
#  last_edit_editor  :string(255)     not null
#  last_edit_comment :text            not null
#  created_at        :datetime        not null
#  updated_at        :datetime        not null
#

# models/public_body.rb:
# A public body, from which information can be requested.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: public_body.rb,v 1.19 2008-02-21 16:15:45 francis Exp $

class PublicBody < ActiveRecord::Base
    validates_presence_of :name
    validates_presence_of :short_name
    validates_presence_of :request_email

    has_many :info_requests

    #acts_as_solr :fields => [:name, :short_name]

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
