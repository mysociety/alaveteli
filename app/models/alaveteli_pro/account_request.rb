# -*- encoding : utf-8 -*-
# Validates pro account request submissions.
#
# Copyright (c) 2017 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class AlaveteliPro::AccountRequest
  include ActiveModel::Validations

  attr_accessor :email, :subject, :reason, :marketing_emails, :training_emails

  validates_presence_of :email, :message => N_("Please enter your email address")
  validates_presence_of :reason, :message => N_("Please enter the reason why you want access")
  validates_presence_of :marketing_emails, :message => N_("Please tell us if you're interested in training and seminars")
  validates_presence_of :training_emails, :message => N_("Please tell us if you want to get updates")

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
