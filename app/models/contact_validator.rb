# == Schema Information
# Schema version: 41
#
# Table name: contact_validators
#
#  name    :string          
#  email   :string          
#  subject :text            
#  message :text            
#

# models/contact_validator.rb:
# Validates contact form submissions.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: contact_validator.rb,v 1.5 2008-03-12 16:07:13 francis Exp $

class ContactValidator < ActiveRecord::BaseWithoutTable
    column :name, :string
    column :email, :string
    column :subject, :text
    column :message, :text

    validates_presence_of :name, :email, :subject, :message

    def validate
        errors.add(:email, "doesn't look like a valid address") unless MySociety::Validate.is_valid_email(self.email)
    end

end
