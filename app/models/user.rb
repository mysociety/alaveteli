# == Schema Information
# Schema version: 108
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
#  email_confirmed        :boolean         default(FALSE), not null
#  url_name               :text            not null
#  last_daily_track_email :datetime        default(Sat Jan 01 00:00:00 UTC 2000)
#  admin_level            :string(255)     default("none"), not null
#  ban_text               :text            default(""), not null
#  about_me               :text            default(""), not null
#  locale                 :string(255)
#  email_bounced_at       :datetime
#  email_bounce_message   :text            default(""), not null
#  no_limit               :boolean         default(FALSE), not null
#

# models/user.rb:
# Model of people who use the site to file requests, make comments etc.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: user.rb,v 1.106 2009-10-01 01:43:36 francis Exp $

require 'digest/sha1'

class User < ActiveRecord::Base
    strip_attributes!

    validates_presence_of :email, :message => _("Please enter your email address")

    validates_presence_of :name, :message => _("Please enter your name")

    validates_presence_of :hashed_password, :message => _("Please enter a password")

    has_many :info_requests, :order => 'created_at desc'
    has_many :user_info_request_sent_alerts
    has_many :post_redirects
    has_many :track_things, :foreign_key => 'tracking_user_id', :order => 'created_at desc'
    has_many :comments, :order => 'created_at desc'
    has_one :profile_photo
    has_many :censor_rules, :order => 'created_at desc'

    attr_accessor :password_confirmation, :no_xapian_reindex
    validates_confirmation_of :password, :message => _("Please enter the same password twice")

    validates_inclusion_of :admin_level, :in => [ 
        'none',
        'super', 
    ], :message => N_('Admin level is not included in list')

    acts_as_xapian :texts => [ :name, :about_me ],
        :values => [ 
             [ :created_at_numeric, 1, "created_at", :number ] # for sorting
        ],
        :terms => [ [ :variety, 'V', "variety" ] ],
        :if => :indexed_by_search?
    def created_at_numeric
        # format it here as no datetime support in Xapian's value ranges
        return self.created_at.strftime("%Y%m%d%H%M%S") 
    end
    
    def variety
        "user"
    end

    def after_initialize
        if self.admin_level.nil?
            self.admin_level = 'none'
        end
        if self.new_record?
            # make alert emails go out at a random time for each new user, so
            # overall they are spread out throughout the day.
            self.last_daily_track_email = User.random_time_in_last_day    
        end
    end

    # requested_by: and commented_by: search queries also need updating after save
    after_update :reindex_referencing_models
    def reindex_referencing_models
        return if no_xapian_reindex == true

        if self.changes.include?('url_name')
            for comment in self.comments
                for info_request_event in comment.info_request_events
                    info_request_event.xapian_mark_needs_index
                end
            end
            for info_request in self.info_requests
                for info_request_event in info_request.info_request_events
                    info_request_event.xapian_mark_needs_index
                end
            end
        end
    end
    
    def get_locale
        if !self.locale.nil?
            locale = self.locale
        else
            locale = I18n.locale
        end
        return locale.to_s
    end

    def visible_comments
        self.comments.find(:all, :conditions => 'visible')
    end

    def validate
        if self.email != "" && !MySociety::Validate.is_valid_email(self.email)
            errors.add(:email, _("Please enter a valid email address")) 
        end
        if MySociety::Validate.is_valid_email(self.name)
            errors.add(:name, _("Please enter your name, not your email address, in the name field.")) 
        end
    end

    # Don't display any leading/trailing spaces
    # XXX we have strip_attributes! now, so perhaps this can be removed (might
    # be still needed for existing cases)
    def name
        name = read_attribute(:name)
        if not name.nil?
            name.strip!
        end
        if self.public_banned?
            name = _("{{user_name}} (Account suspended)", :user_name=>name)
        end
        name
    end

    # Return user given login email, password and other form parameters (e.g. name)
    #  
    # The specific_user_login parameter says that login as a particular user is
    # expected, so no parallel registration form is being displayed.
    def User.authenticate_from_form(params, specific_user_login = false)
        params[:email].strip!

        if specific_user_login
            auth_fail_message = _("Either the email or password was not recognised, please try again.")
        else
            auth_fail_message = _("Either the email or password was not recognised, please try again. Or create a new account using the form on the right.")
        end

        user = self.find_user_by_email(params[:email])
        if user
            # There is user with email, check password
            if !user.has_this_password?(params[:password])
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
    def User.find_user_by_email(email)
        return self.find(:first, :conditions => [ 'lower(email) = lower(?)', email ] )
    end

    # When name is changed, also change the url name
    def name=(name)
        write_attribute(:name, name)
        self.update_url_name
    end
    def update_url_name
        url_name = MySociety::Format.simplify_url_part(self.name, 'user', 32)
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

    def has_this_password?(password)
        expected_password = User.encrypted_password(password, self.salt)
        return self.hashed_password == expected_password
    end

# For use in to/from in email messages
    def name_and_email
        return TMail::Address.address_from_name_and_email(self.name, self.email).to_s
    end

    # The "internal admin" is a special user for internal use.
    def User.internal_admin_user
        contact_email = MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost')
        u = User.find_by_email(contact_email)
        if u.nil?
            password = PostRedirect.generate_random_token
            u = User.new(
                :name => 'Internal admin user',
                :email => contact_email,
                :password => password,
                :password_confirmation => password
            )
            u.save!
        end

        return u
    end

    # Returns list of requests which the user hasn't described (and last
    # changed more than a day ago)
    def get_undescribed_requests
        self.info_requests.find(
            :all, 
            :conditions => [ 'awaiting_description = ? and ' + InfoRequest.last_event_time_clause + ' < ?', 
                true, Time.now() - 1.day 
            ] 
        )
    end

    # Can the user make new requests, without having to describe state of (most) existing ones?
    def can_leave_requests_undescribed?
        # XXX should be flag in database really
        if self.url_name == "heather_brooke" || self.url_name == "heather_brooke_2"
            return true
        end
        return false
    end

    # Does the user magically gain powers as if they owned every request?
    # e.g. Can classify it
    def owns_every_request?
        self.admin_level == 'super'
    end
    
    def User.owns_every_request?(user)
      !user.nil? && user.owns_every_request?
    end

    # Can the user see every request, even hidden ones?
    def User.view_hidden_requests?(user)
      !user.nil? && user.admin_level == 'super'
    end

    # Should the user be kept logged into their own account
    # if they follow a /c/ redirect link belonging to another user?
    def User.stay_logged_in_on_redirect?(user)
      !user.nil? && user.admin_level == 'super'
    end
     
    # Does the user get "(admin)" links on each page on the main site?
    def admin_page_links?
        self.admin_level == 'super'
    end
    # Is it public that they are banned?
    def public_banned?
        !self.ban_text.empty?
    end
    # Various ways the user can be banned, and text to describe it if failed
    def can_file_requests?
        self.ban_text.empty? && !self.exceeded_limit?
    end
    def exceeded_limit?
        # Some users have no limit
        return false if self.no_limit
        
        # Has the user issued as many as MAX_REQUESTS_PER_USER_PER_DAY requests in the past 24 hours?
        daily_limit = MySociety::Config.get("MAX_REQUESTS_PER_USER_PER_DAY")
        return false if daily_limit.nil?
        recent_requests = InfoRequest.count(:conditions => ["user_id = ? and created_at > now() - '1 day'::interval", self.id])
        
        return (recent_requests >= daily_limit)
    end
    def next_request_permitted_at
        return nil if self.no_limit
        
        daily_limit = MySociety::Config.get("MAX_REQUESTS_PER_USER_PER_DAY")
        n_most_recent_requests = InfoRequest.all(:conditions => ["user_id = ? and created_at > now() - '1 day'::interval", self.id], :order => "created_at DESC", :limit => daily_limit)
        return nil if n_most_recent_requests.size < daily_limit
        
        nth_most_recent_request = n_most_recent_requests[-1]
        return nth_most_recent_request.created_at + 1.day
    end
    def can_make_followup?
        self.ban_text.empty?
    end
    def can_make_comments?
        self.ban_text.empty?
    end
    def can_contact_other_users?
        self.ban_text.empty?
    end
    def can_fail_html
        if ban_text
            text = self.ban_text.strip
        else
            raise "Unknown reason for ban"
        end
        text = CGI.escapeHTML(text)
        text = MySociety::Format.make_clickable(text, :contract => 1)
        text = text.gsub(/\n/, '<br>')
        return text
    end

    # Returns domain part of user's email address
    def email_domain
        return PublicBody.extract_domain_from_email(self.email)
    end

    # A photograph of the user (to make it all more human)
    def set_profile_photo(new_profile_photo)
        ActiveRecord::Base.transaction do
            if !self.profile_photo.nil?
                self.profile_photo.destroy
            end
            self.profile_photo = new_profile_photo
            self.save
        end
    end

    # Used for default values of last_daily_track_email
    def User.random_time_in_last_day
        earliest_time = Time.now() - 1.day
        latest_time = Time.now
        return earliest_time + rand(latest_time - earliest_time).seconds
    end

    # Alters last_daily_track_email for every user, so alerts will be sent
    # spread out fairly evenly throughout the day, balancing load on the
    # server. This is intended to be called by hand from the Ruby console.  It
    # will mean quite a few users may get more than one email alert the day you
    # do it, so have a care and run it rarely.
    #
    # This SQL statement is useful for seeing how spread out users are at the moment:
    # select extract(hour from last_daily_track_email) as h, count(*) from users group by extract(hour from last_daily_track_email) order by h;
    def User.spread_alert_times_across_day
        for user in self.find(:all)
            user.last_daily_track_email = User.random_time_in_last_day
            user.save!
        end
        nil # so doesn't print all users on console
    end

    # Return about me text for display as HTML
    def get_about_me_for_html_display
        text = self.about_me.strip
        text = CGI.escapeHTML(text)
        text = MySociety::Format.make_clickable(text, :contract => 1)
        text = text.gsub(/\n/, '<br>')
        return text
    end

    def json_for_api
        return { 
            :id => self.id,
            :url_name => self.url_name,
            :name => self.name,
            :ban_text => self.ban_text,
            :about_me => self.about_me,
            # :profile_photo => self.profile_photo # ought to have this, but too hard to get URL out for now
            # created_at / updated_at we only show the year on the main page for privacy reasons, so don't put here
        }
    end

    def record_bounce(message)
        self.email_bounced_at = Time.now
        self.email_bounce_message = message
        self.save!
    end
    
    def should_be_emailed?
        return (self.email_confirmed && self.email_bounced_at.nil?)
    end
    
    def indexed_by_search?
        return self.email_confirmed
    end

    ## Private instance methods
    private

    def create_new_salt
        self.salt = self.object_id.to_s + rand.to_s
    end
    
    ## Class methods
    def User.encrypted_password(password, salt)
        string_to_hash = password + salt # XXX need to add a secret here too?
        Digest::SHA1.hexdigest(string_to_hash)
    end
        
    def User.record_bounce_for_email(email, message)
        user = User.find_user_by_email(email)
        return false if user.nil?
        
        if user.email_bounced_at.nil?
            user.record_bounce(message)
        end
        return true
    end
end

