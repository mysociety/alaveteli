# == Schema Information
# Schema version: 114
#
# Table name: about_me_validators
#
#  about_me :text            default("I..."), not null
#

# models/about_me_validator.rb:
# Validates editing about me text on user profile pages.
#
# Copyright (c) 2010 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/

class AboutMeValidator < ActiveRecord::BaseWithoutTable
    strip_attributes!

    column :about_me, :text, "I...", false

    def validate
        if !self.about_me.blank? && self.about_me.size > 500
            errors.add(:about_me, _("Please keep it shorter than 500 characters"))
        end
    end

end
