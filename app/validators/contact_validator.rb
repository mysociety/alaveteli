# -*- encoding : utf-8 -*-
# models/contact_validator.rb:
# Validates contact form submissions.
#
# Copyright (c) 2008 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class ContactValidator
  include ActiveModel::Validations

  attr_accessor :name, :email, :subject, :message, :comment

  validates_presence_of :name, :message => N_("Please enter your name")
  validates_presence_of :email, :message => N_("Please enter your email address")
  validates_presence_of :subject, :message => N_("Please enter a subject")
  validates_presence_of :message, :message => N_("Please enter the message you want to send")
  validate :email_format

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  private

  def email_format
    unless MySociety::Validate.is_valid_email(email)
      errors.add(:email, _("Email doesn't look like a valid address"))
    end
  end
end
