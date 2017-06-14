# -*- encoding : utf-8 -*-
# models/changeemail_validator.rb:
# Validates email change form submissions.
#
# Copyright (c) 2010 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

class ChangeEmailValidator
  include ActiveModel::Validations

  attr_accessor :old_email,
                :new_email,
                :password,
                :user_circumstance,
                :logged_in_user

  validates_presence_of :old_email,
                        :message => N_("Please enter your old email address")

  validates_presence_of :new_email,
                        :message => N_("Please enter your new email address")

  validates_presence_of :password,
                        :message => N_("Please enter your password"),
                        :unless => :changing_email

  validate :password_and_format_of_email

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value)
    end
  end

  def changing_email
    self.user_circumstance == 'change_email'
  end

  private

  def password_and_format_of_email
    check_email_is_present_and_valid(:old_email)

    if errors[:old_email].blank?
      if !email_belongs_to_user?(old_email)
        errors.add(:old_email, _("Old email address isn't the same as the address of the account you are logged in with"))
      elsif !changing_email && password && !correct_password?
        if errors[:password].blank?
          errors.add(:password, _("Password is not correct"))
        end
      end
    end

    check_email_is_present_and_valid(:new_email)
  end

  def check_email_is_present_and_valid(email)
    if !send(email).blank? && !MySociety::Validate.is_valid_email(send(email))
      msg_string = check_email_is_present_and_valid_msg_string(email)
      errors.add(email, msg_string)
    end
  end

  def check_email_is_present_and_valid_msg_string(email)
    case email.to_sym
    when :old_email then _("Old email doesn't look like a valid address")
    when :new_email then _("New email doesn't look like a valid address")
    else
      raise "Unsupported email type #{ email }"
    end
  end

  def email_belongs_to_user?(email)
    email.downcase == logged_in_user.email.downcase
  end

  def correct_password?
    logged_in_user.has_this_password?(password)
  end

end
