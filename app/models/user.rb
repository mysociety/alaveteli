# == Schema Information
# Schema version: 54
#
# Table name: users
#
#  id                     :integer         not null, primary key
#  email                  :string(255)     not null
#  name                   :string(255)     not null
#  hashed_password        :string(255)     not null
#  salt                   :string(255)     not null
#  created_at             :datetime        not null
#  updated_at             :datetime        not null
#  email_confirmed        :boolean         default(false), not null
#  url_name               :text            not null
#  last_daily_track_email :datetime        default(Sat Jan 01 00:00:00 UTC 2000)
#

# models/user.rb:
# Model of people who use the site to file requests, make comments etc.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: user.rb,v 1.54 2008-05-12 01:38:38 francis Exp $

require 'digest/sha1'

class User < ActiveRecord::Base
    validates_presence_of :email, :message => "^Please enter your email address"

    validates_presence_of :name, :message => "^Please enter your name"
    validates_presence_of :url_name

    validates_presence_of :hashed_password, :message => "^Please enter a password"

    has_many :info_requests, :order => 'created_at desc'
    has_many :user_info_request_sent_alerts
    has_many :post_redirects
    has_many :track_things, :foreign_key => 'tracking_user_id', :order => 'created_at desc'

    attr_accessor :password_confirmation
    validates_confirmation_of :password, :message =>"^Please enter the same password twice"

    acts_as_xapian :texts => [ :name ],
        :values => [ [ :created_at, 0, "created_at", :date ] ],
        :terms => [ [ :variety, 'V', "variety" ] ]
    def variety
        "user"
    end

    def validate
        errors.add(:email, "doesn't look like a valid address") unless MySociety::Validate.is_valid_email(self.email)
        if MySociety::Validate.is_valid_email(self.name)
            errors.add(:name, "^Please enter your name, not your email address, in the name field.") 
        end
    end

    # Don't display any leading/trailing spaces
    def name
        name = read_attribute(:name)
        if not name.nil?
            name.strip!
        end
        name
    end

    # Return user given login email, password and other form parameters (e.g. name)
    #  
    # The specific_user_login parameter says that login as a particular user is
    # expected, so no parallel registration form is being displayed.
    def self.authenticate_from_form(params, specific_user_login = false)
        if specific_user_login
            auth_fail_message = "Either the email or password was not recognised, please try again."
        else
            auth_fail_message = "Either the email or password was not recognised, please try again. Or create a new account using the form on the right."
        end

        user = self.find_user_by_email(params[:email])
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
            # deliberately same message as above so as not to leak whether registered
            user.errors.add_to_base(auth_fail_message)
        end
        user
    end

    # Case-insensitively find a user from their email
    def self.find_user_by_email(email)
        return self.find(:first, :conditions => [ 'email ilike ?', email ] ) # using ilike for case insensitive
    end

    # When name is changed, also change the url name
    def name=(name)
        write_attribute(:name, name)
        self.update_url_name
    end
    def update_url_name
        url_name = MySociety::Format.simplify_url_part(self.name, 32)
        # For user with same name as others, add on arbitary numeric identifier
        unique_url_name = url_name
        suffix_num = 2 # as there's already one without numeric suffix
        while not User.find_by_url_name(unique_url_name, :conditions => self.id.nil? ? nil : ["id <> ?", self.id] ).nil?
            unique_url_name = url_name + "_" + suffix_num.to_s
            suffix_num = suffix_num + 1
        end
        write_attribute(:url_name, unique_url_name)
    end

    # Virtual password attribute, which stores the hashed password, rather than plain text.
    def password
        @password
    end
    def password=(pwd)
        @password = pwd
        if pwd.blank?
            self.hashed_password = nil
            return
        end
        create_new_salt
        self.hashed_password = User.encrypted_password(self.password, self.salt)
    end

    # For use in to/from in email messages
    def name_and_email
        return self.name + " <" + self.email + ">"
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

