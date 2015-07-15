# -*- encoding : utf-8 -*-
# models/about_me_validator.rb:
# Validates editing about me text on user profile pages.
#
# Copyright (c) 2010 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AboutMeValidator
  include ActiveModel::Validations

  attr_accessor :about_me

  validates_length_of :about_me, :maximum => 500, :message => _("Please keep it shorter than 500 characters")

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end
end
