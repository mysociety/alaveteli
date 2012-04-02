# == Schema Information
# Schema version: 108
#
# Table name: change_email_validators
#
#  old_email         :string
#  new_email         :string
#  password          :string
#  user_circumstance :string
#

# models/changeemail_validator.rb:
# Validates email change form submissions.
#
# Copyright (c) 2010 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: contact_validator.rb,v 1.32 2009-09-17 21:10:05 francis Exp $

class ChangeEmailValidator < ActiveRecord::BaseWithoutTable
    strip_attributes!

    column :old_email, :string
    column :new_email, :string
    column :password, :string
    column :user_circumstance, :string

    attr_accessor :logged_in_user

    validates_presence_of :old_email, :message => N_("Please enter your old email address")
    validates_presence_of :new_email, :message => N_("Please enter your new email address")
    validates_presence_of :password, :message => N_("Please enter your password"), :unless => :changing_email
    
    def changing_email()
      self.user_circumstance == 'change_email'
    end

    def validate
        if !self.old_email.blank? && !MySociety::Validate.is_valid_email(self.old_email)
            errors.add(:old_email, _("Old email doesn't look like a valid address"))
        end

        if !errors[:old_email]
            if self.old_email.downcase != self.logged_in_user.email.downcase
                errors.add(:old_email, _("Old email address isn't the same as the address of the account you are logged in with"))
            elsif (!self.changing_email) && (!self.logged_in_user.has_this_password?(self.password))
                if !errors[:password]
                    errors.add(:password, _("Password is not correct"))
                end
            end
        end

        if !self.new_email.blank? && !MySociety::Validate.is_valid_email(self.new_email)
            errors.add(:new_email, _("New email doesn't look like a valid address"))
        end
    end

end
