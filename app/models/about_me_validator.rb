# -*- encoding : utf-8 -*-
# models/about_me_validator.rb:
# Validates editing about me text on user profile pages.
#
# Copyright (c) 2010 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AboutMeValidator
    include ActiveModel::Validations

    attr_accessor :about_me

    # TODO: Switch to built in validations
    validate :length_of_about_me

    def initialize(attributes = {})
        attributes.each do |name, value|
            send("#{name}=", value)
        end
    end

    private

    def length_of_about_me
        if !about_me.blank? && about_me.size > 500
            errors.add(:about_me, _("Please keep it shorter than 500 characters"))
        end
    end
end
