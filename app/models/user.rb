# models/user.rb:
# Model of people who use the site to file requests, make comments etc.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: user.rb,v 1.12 2007-11-07 10:26:30 francis Exp $

require 'digest/sha1'

class User < ActiveRecord::Base
    validates_presence_of :email, :message => "^Please enter your email address"
    validates_uniqueness_of :email, :case_sensitive => false

    validates_presence_of :name
    validates_presence_of :hashed_password, :message => "^Please enter a password"

    has_many :info_requests

    attr_accessor :password_confirmation
    validates_confirmation_of :password, :message =>"^Please enter the same password twice"

    def validate
        errors.add(:email, "doesn't look like a valid address") unless MySociety::Validate.is_valid_email(self.email)
    end

    # Return user given login email, password and other form parameters (e.g. name)
    def self.authenticate_from_form(params)
        auth_fail_message = "Email or password not recognised, please try again"
        user = self.find(:first, :conditions => [ 'email ilike ?', params[:email] ] ) # using ilike for case insensitive
        if user
            # There is user with email, check password
            expected_password = encrypted_password(params[:password], user.salt)
            if user.hashed_password != expected_password
                user.errors.add_to_base(auth_fail_message)
            end
        else
            # No user of same email, make one (that we don't save in the database)
            # for the forms code to use.
            user = User.new(params)
            # deliberately same message as above so as not to leak whether 
            user.errors.add_to_base(auth_fail_message)
        end
        user
    end

    # Virtual password attribute, which stores the hashed password, rather than plain text.
    def password
        @password
    end
    def password=(pwd)
        @password = pwd
        return if pwd.blank?
        create_new_salt
        self.hashed_password = User.encrypted_password(self.password, self.salt)
    end

    private

    def self.encrypted_password(password, salt)
        string_to_hash = password + salt # XXX need to add a secret here too?
        Digest::SHA1.hexdigest(string_to_hash)
    end
    
    def create_new_salt
        self.salt = self.object_id.to_s + rand.to_s
    end
end

