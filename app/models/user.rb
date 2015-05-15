# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: users
#
#  id                      :integer          not null, primary key
#  email                   :string(255)      not null
#  name                    :string(255)      not null
#  hashed_password         :string(255)      not null
#  salt                    :string(255)      not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  email_confirmed         :boolean          default(FALSE), not null
#  url_name                :text             not null
#  last_daily_track_email  :datetime         default(Sat Jan 01 00:00:00 UTC 2000)
#  admin_level             :string(255)      default("none"), not null
#  ban_text                :text             default(""), not null
#  about_me                :text             default(""), not null
#  locale                  :string(255)
#  email_bounced_at        :datetime
#  email_bounce_message    :text             default(""), not null
#  no_limit                :boolean          default(FALSE), not null
#  receive_email_alerts    :boolean          default(TRUE), not null
#  can_make_batch_requests :boolean          default(FALSE), not null
#

require 'digest/sha1'

class User < ActiveRecord::Base
    strip_attributes!

    attr_accessor :password_confirmation, :no_xapian_reindex

    has_many :info_requests, :order => 'created_at desc'
    has_many :user_info_request_sent_alerts
    has_many :post_redirects
    has_many :track_things, :foreign_key => 'tracking_user_id', :order => 'created_at desc'
    has_many :comments, :order => 'created_at desc'
    has_one :profile_photo
    has_many :censor_rules, :order => 'created_at desc'
    has_many :info_request_batches, :order => 'created_at desc'
    has_many :request_classifications

    validates_presence_of :email, :message => _("Please enter your email address")
    validates_presence_of :name, :message => _("Please enter your name")
    validates_presence_of :hashed_password, :message => _("Please enter a password")
    validates_confirmation_of :password, :message => _("Please enter the same password twice")
    validates_inclusion_of :admin_level, :in => [
        'none',
        'super',
    ], :message => N_('Admin level is not included in list')

    validate :email_and_name_are_valid

    after_initialize :set_defaults
    after_save :purge_in_cache
    after_update :reindex_referencing_models

    acts_as_xapian :texts => [ :name, :about_me ],
        :values => [
             [ :created_at_numeric, 1, "created_at", :number ] # for sorting
        ],
        :terms => [ [ :variety, 'V', "variety" ] ],
        :if => :indexed_by_search?

    # Return user given login email, password and other form parameters (e.g. name)
    #
    # The specific_user_login parameter says that login as a particular user is
    # expected, so no parallel registration form is being displayed.
    def self.authenticate_from_form(params, specific_user_login = false)
        params[:email].strip!

        if specific_user_login
            auth_fail_message = _("Either the email or password was not recognised, please try again.")
        else
            auth_fail_message = _("Either the email or password was not recognised, please try again. Or create a new account using the form on the right.")
        end

        user = find_user_by_email(params[:email])
        if user
            # There is user with email, check password
            unless user.has_this_password?(params[:password])
                user.errors.add(:base, auth_fail_message)
            end
        else
            # No user of same email, make one (that we don't save in the database)
            # for the forms code to use.
            user = User.new(params)
            # deliberately same message as above so as not to leak whether registered
            user.errors.add(:base, auth_fail_message)
        end
        user
    end

    # Case-insensitively find a user from their email
    def self.find_user_by_email(email)
        self.find(:first, :conditions => [ 'lower(email) = lower(?)', email ] )
    end

    # The "internal admin" is a special user for internal use.
    def self.internal_admin_user
        user = User.find_by_email(AlaveteliConfiguration::contact_email)
        if user.nil?
            password = PostRedirect.generate_random_token
            user = User.new(
                :name => 'Internal admin user',
                :email => AlaveteliConfiguration.contact_email,
                :password => password,
                :password_confirmation => password
            )
            user.save!
        end

        user
    end

    def self.owns_every_request?(user)
      !user.nil? && user.owns_every_request?
    end

    # Can the user see every request, response, and outgoing message, even hidden ones?
    def self.view_hidden?(user)
      !user.nil? && user.super?
    end

    # Should the user be kept logged into their own account
    # if they follow a /c/ redirect link belonging to another user?
    def self.stay_logged_in_on_redirect?(user)
      !user.nil? && user.super?
    end

    # Used for default values of last_daily_track_email
    def self.random_time_in_last_day
        earliest_time = Time.now - 1.day
        latest_time = Time.now
        earliest_time + rand(latest_time - earliest_time).seconds
    end

    # Alters last_daily_track_email for every user, so alerts will be sent
    # spread out fairly evenly throughout the day, balancing load on the
    # server. This is intended to be called by hand from the Ruby console.  It
    # will mean quite a few users may get more than one email alert the day you
    # do it, so have a care and run it rarely.
    #
    # This SQL statement is useful for seeing how spread out users are at the moment:
    # select extract(hour from last_daily_track_email) as h, count(*) from users group by extract(hour from last_daily_track_email) order by h;
    def self.spread_alert_times_across_day
        self.find(:all).each do |user|
            user.last_daily_track_email = User.random_time_in_last_day
            user.save!
        end
        nil # so doesn't print all users on console
    end

    def self.encrypted_password(password, salt)
        string_to_hash = password + salt # TODO: need to add a secret here too?
        Digest::SHA1.hexdigest(string_to_hash)
    end

    def self.record_bounce_for_email(email, message)
        user = User.find_user_by_email(email)
        return false if user.nil?

        user.record_bounce(message) if user.email_bounced_at.nil?
        return true
    end

    def created_at_numeric
        # format it here as no datetime support in Xapian's value ranges
        created_at.strftime("%Y%m%d%H%M%S")
    end

    def variety
        "user"
    end

    # requested_by: and commented_by: search queries also need updating after save
    def reindex_referencing_models
        return if no_xapian_reindex == true

        if changes.include?('url_name')
            comments.each do |comment|
                comment.info_request_events.each do |info_request_event|
                    info_request_event.xapian_mark_needs_index
                end
            end

            info_requests.each do |info_request|
                info_request.info_request_events.each do |info_request_event|
                    info_request_event.xapian_mark_needs_index
                end
            end
        end
    end

    def get_locale
        (locale || I18n.locale).to_s
    end

    def visible_comments
        comments.find(:all, :conditions => 'visible')
    end

    # Don't display any leading/trailing spaces
    # TODO: we have strip_attributes! now, so perhaps this can be removed (might
    # be still needed for existing cases)
    def name
        name = read_attribute(:name)
        if not name.nil?
            name.strip!
        end
        if banned?
            # Use interpolation to return a string rather than a SafeBuffer so that
            # gsub can be called on it until we upgrade to Rails 3.2. The name returned
            # is not marked as HTML safe so will be escaped automatically in views. We
            # do this in two steps so the string still gets picked up for translation
            name = _("{{user_name}} (Account suspended)", :user_name => name.html_safe)
            name = "#{name}"
        end
        name
    end

    # When name is changed, also change the url name
    def name=(name)
        write_attribute(:name, name)
        update_url_name
    end

    def update_url_name
        url_name = MySociety::Format.simplify_url_part(name, 'user', 32)
        # For user with same name as others, add on arbitary numeric identifier
        unique_url_name = url_name
        suffix_num = 2 # as there's already one without numeric suffix
        while not User.find_by_url_name(unique_url_name, :conditions => id.nil? ? nil : ["id <> ?", id] ).nil?
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
        self.hashed_password = User.encrypted_password(password, salt)
    end

    def has_this_password?(password)
        expected_password = User.encrypted_password(password, salt)
        hashed_password == expected_password
    end

# For use in to/from in email messages
    def name_and_email
        MailHandler.address_from_name_and_email(name, email)
    end

    # Returns list of requests which the user hasn't described (and last
    # changed more than a day ago)
    def get_undescribed_requests
        info_requests.where(
            "awaiting_description = ? and #{ InfoRequest.last_event_time_clause } < ?",
            true, 1.day.ago
        )
    end

    # Can the user make new requests, without having to describe state of (most) existing ones?
    def can_leave_requests_undescribed?
        # TODO: should be flag in database really
        if url_name == "heather_brooke" || url_name == "heather_brooke_2"
            return true
        end
        return false
    end

    # Does the user magically gain powers as if they owned every request?
    # e.g. Can classify it
    def owns_every_request?
        super?
    end

    # Does this user have extraordinary powers?
    def super?
        admin_level == 'super'
    end

    # Does the user get "(admin)" links on each page on the main site?
    def admin_page_links?
        super?
    end

    # Is it public that they are banned?
    def banned?
      !ban_text.empty?
    end

    def public_banned?
      warn %q([DEPRECATION] User#public_banned? will be replaced with
              User#banned? as of 0.22).squish
      banned?
    end

    # Various ways the user can be banned, and text to describe it if failed
    def can_file_requests?
        ban_text.empty? && !exceeded_limit?
    end
    def exceeded_limit?
        # Some users have no limit
        return false if no_limit

        # Batch request users don't have a limit
        return false if can_make_batch_requests?

        # Has the user issued as many as MAX_REQUESTS_PER_USER_PER_DAY requests in the past 24 hours?
        return false if AlaveteliConfiguration.max_requests_per_user_per_day.blank?
        recent_requests = InfoRequest.count(:conditions => ["user_id = ? and created_at > now() - '1 day'::interval", id])

        recent_requests >= AlaveteliConfiguration.max_requests_per_user_per_day
    end
    def next_request_permitted_at
        return nil if no_limit

        n_most_recent_requests = InfoRequest.all(:conditions => ["user_id = ? and created_at > now() - '1 day'::interval", id],
                                                 :order => "created_at DESC",
                                                 :limit => AlaveteliConfiguration::max_requests_per_user_per_day)
        return nil if n_most_recent_requests.size < AlaveteliConfiguration::max_requests_per_user_per_day

        nth_most_recent_request = n_most_recent_requests[-1]
        nth_most_recent_request.created_at + 1.day
    end
    def can_make_followup?
        ban_text.empty?
    end
    def can_make_comments?
        ban_text.empty?
    end
    def can_contact_other_users?
        ban_text.empty?
    end
    def can_fail_html
        if ban_text
            text = ban_text.strip
        else
            raise "Unknown reason for ban"
        end
        text = CGI.escapeHTML(text)
        text = MySociety::Format.make_clickable(text, :contract => 1)
        text = text.gsub(/\n/, '<br>')
        text.html_safe
    end

    # Returns domain part of user's email address
    def email_domain
        PublicBody.extract_domain_from_email(email)
    end

    # A photograph of the user (to make it all more human)
    def set_profile_photo(new_profile_photo)
        ActiveRecord::Base.transaction do
            profile_photo.destroy unless profile_photo.nil?
            self.profile_photo = new_profile_photo
            save
        end
    end

    # Return about me text for display as HTML
    # TODO: Move this to a view helper
    def get_about_me_for_html_display
        text = about_me.strip
        text = CGI.escapeHTML(text)
        text = MySociety::Format.make_clickable(text, :contract => 1)
        text = text.gsub(/\n/, '<br>')
        text.html_safe
    end

    def json_for_api
        {
            :id => id,
            :url_name => url_name,
            :name => name,
            :ban_text => ban_text,
            :about_me => about_me,
            # :profile_photo => self.profile_photo # ought to have this, but too hard to get URL out for now
            # created_at / updated_at we only show the year on the main page for privacy reasons, so don't put here
        }
    end

    def record_bounce(message)
        self.email_bounced_at = Time.now
        self.email_bounce_message = message
        save!
    end

    def should_be_emailed?
        email_confirmed && email_bounced_at.nil?
    end

    def indexed_by_search?
        email_confirmed
    end

    def for_admin_column(complete = false)
      if complete
        columns = self.class.content_columns
      else
        columns = self.class.content_columns.map do |c|
            c if %w(created_at updated_at admin_level email_confirmed).include?(c.name)
        end.compact
      end
      columns.each do |column|
        yield(column.human_name, send(column.name), column.type.to_s, column.name)
      end
    end

    private

    def create_new_salt
        self.salt = object_id.to_s + rand.to_s
    end

    def set_defaults
        if admin_level.nil?
            self.admin_level = 'none'
        end
        if new_record?
            # make alert emails go out at a random time for each new user, so
            # overall they are spread out throughout the day.
            self.last_daily_track_email = User.random_time_in_last_day
        end
    end

    def email_and_name_are_valid
        if email != "" && !MySociety::Validate.is_valid_email(email)
            errors.add(:email, _("Please enter a valid email address"))
        end
        if MySociety::Validate.is_valid_email(name)
            errors.add(:name, _("Please enter your name, not your email address, in the name field."))
        end
    end

    def purge_in_cache        
        info_requests.each { |x| x.purge_in_cache } if name_changed?
    end

end

