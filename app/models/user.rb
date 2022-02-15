# == Schema Information
# Schema version: 20220210114052
#
# Table name: users
#
#  id                                :integer          not null, primary key
#  email                             :string           not null
#  name                              :string           not null
#  hashed_password                   :string           not null
#  salt                              :string
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  email_confirmed                   :boolean          default(FALSE), not null
#  url_name                          :text             not null
#  last_daily_track_email            :datetime         default(Sat, 01 Jan 2000 00:00:00.000000000 GMT +00:00)
#  ban_text                          :text             default(""), not null
#  about_me                          :text             default(""), not null
#  locale                            :string
#  email_bounced_at                  :datetime
#  email_bounce_message              :text             default(""), not null
#  no_limit                          :boolean          default(FALSE), not null
#  receive_email_alerts              :boolean          default(TRUE), not null
#  can_make_batch_requests           :boolean          default(FALSE), not null
#  otp_enabled                       :boolean          default(FALSE), not null
#  otp_secret_key                    :string
#  otp_counter                       :integer          default(1)
#  confirmed_not_spam                :boolean          default(FALSE), not null
#  comments_count                    :integer          default(0), not null
#  info_requests_count               :integer          default(0), not null
#  track_things_count                :integer          default(0), not null
#  request_classifications_count     :integer          default(0), not null
#  public_body_change_requests_count :integer          default(0), not null
#  info_request_batches_count        :integer          default(0), not null
#  daily_summary_hour                :integer
#  daily_summary_minute              :integer
#  closed_at                         :datetime
#  login_token                       :string
#

class User < ApplicationRecord
  include AlaveteliFeatures::Helpers
  include AlaveteliPro::PhaseCounts
  include User::Authentication
  include User::LoginToken
  include User::OneTimePassword
  include User::Survey

  rolify before_add: :setup_pro_account
  strip_attributes :allow_empty => true

  attr_accessor :no_xapian_reindex

  has_many :info_requests,
           -> { order('info_requests.created_at desc') },
           :inverse_of => :user,
           :dependent => :destroy
  has_many :info_request_events,
           -> { reorder('created_at desc') },
           :through => :info_requests
  has_many :embargoes,
           :inverse_of => :user,
           :through => :info_requests
  has_many :draft_info_requests,
           -> { order('created_at desc') },
           :inverse_of => :user,
           :dependent => :destroy
  has_many :user_info_request_sent_alerts,
           :inverse_of => :user,
           :dependent => :destroy
  has_many :post_redirects,
           -> { order('created_at desc') },
           :inverse_of => :user,
           :dependent => :destroy
  has_many :track_things,
           -> { order('created_at desc') },
           :inverse_of => :tracking_user,
           :foreign_key => 'tracking_user_id',
           :dependent => :destroy
  has_many :citations,
           -> { order('created_at desc') },
           inverse_of: :user,
           dependent: :destroy
  has_many :comments,
           -> { order('created_at desc') },
           :inverse_of => :user,
           :dependent => :destroy
  has_many :public_body_change_requests,
           -> { order('created_at desc') },
           :inverse_of => :user,
           :dependent => :destroy
  has_one :profile_photo,
          :inverse_of => :user,
          :dependent => :destroy
  has_many :censor_rules,
           -> { order('created_at desc') },
           :inverse_of => :user,
           :dependent => :destroy
  has_many :info_request_batches,
           -> { order('created_at desc') },
           :inverse_of => :user,
           :dependent => :destroy
  has_many :draft_info_request_batches,
           -> { order('created_at desc') },
           :inverse_of => :user,
           :dependent => :destroy,
           :class_name => 'AlaveteliPro::DraftInfoRequestBatch'
  has_many :request_classifications,
           :inverse_of => :user,
           :dependent => :destroy
  has_one :pro_account,
          :inverse_of => :user,
          :dependent => :destroy
  has_many :request_summaries,
           :inverse_of => :user,
           :dependent => :destroy,
           :class_name => 'AlaveteliPro::RequestSummary'
  has_many :notifications,
           :inverse_of => :user,
           :dependent => :destroy
  has_many :track_things_sent_emails,
           :inverse_of => :user,
           :dependent => :destroy
  has_many :track_things_sent_emails,
           :dependent => :destroy
  has_many :announcements,
           :inverse_of => :user
  has_many :announcement_dismissals,
           :inverse_of => :user,
           :dependent => :destroy
  has_many :memberships, class_name: 'Project::Membership'
  has_many :projects, through: :memberships

  scope :active, -> { not_banned.not_closed }
  scope :banned, -> { where.not(ban_text: "") }
  scope :not_banned, -> { where(ban_text: "") }
  scope :closed, -> { where.not(closed_at: nil) }
  scope :not_closed, -> { where(closed_at: nil) }

  validates_presence_of :email, :message => _("Please enter your email address")
  validates_presence_of :name, :message => _("Please enter your name")

  validates_length_of :about_me,
    :maximum => 500,
    :message => _("Please keep it shorter than 500 characters")

  validates :email, :uniqueness => {
                      :case_sensitive => false,
                      :message => _("This email is already in use") }

  validate :email_and_name_are_valid

  after_initialize :set_defaults
  after_update :reindex_referencing_models, :update_pro_account

  acts_as_xapian :texts => [ :name, :about_me ],
    :values => [
      [ :created_at_numeric, 1, "created_at", :number ] # for sorting
  ],
  :terms => [ [ :variety, 'V', "variety" ] ],
  :if => :indexed_by_search?


  def self.pro
    with_role :pro
  end

  # Return user given login email, password and other form parameters (e.g. name)
  #
  # The specific_user_login parameter says that login as a particular user is
  # expected, so no parallel registration form is being displayed.
  def self.authenticate_from_form(params, specific_user_login = false)
    params[:email].strip!

    if specific_user_login
      auth_fail_message = _("Either the email or password was not recognised, please try again.")
    else
      auth_fail_message = _("Either the email or password was not recognised, please try again. Or create a new account using the form on the left.")
    end

    user = find_user_by_email(params[:email])
    if user
      # There is user with email, check password
      unless user.has_this_password?(params[:password])
        user.errors.add(:base, auth_fail_message)
      end

      if user.has_this_password?(params[:password]) && user.closed?
        logger.info "Closed user attempted login: #{ params[:email] }"
        user.errors.add(:base, _('This account has been closed.'))
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
    return nil if email.blank?
    self.where('lower(email) = lower(?)', email.strip).first
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
    warn %q([DEPRECATION] User#owns_every_request? will be removed in 0.41.
            It has been replaced by User#owns_every_request?).squish
    user&.owns_every_request?
  end

  def self.view_hidden?(user)
    warn %q([DEPRECATION] User.view_hidden? will be removed in 0.41.
            It has been replaced by User#view_hidden?).squish
    user&.view_hidden?
  end

  def self.view_embargoed?(user)
    warn %q([DEPRECATION] User.view_embargoed? will be removed in 0.41.
            It has been replaced by User#view_embargoed?).squish
    user&.view_embargoed?
  end

  def self.view_hidden_and_embargoed?(user)
    warn %q([DEPRECATION] User.view_hidden_and_embargoed? will be removed in
            0.41. It has been replaced by User#view_hidden_and_embargoed?).
            squish
    user&.view_hidden_and_embargoed?
  end

  # Should the user be kept logged into their own account
  # if they follow a /c/ redirect link belonging to another user?
  def self.stay_logged_in_on_redirect?(user)
    !user.nil? && user.is_admin?
  end

  # Used for default values of last_daily_track_email
  def self.random_time_in_last_day
    earliest_time = Time.zone.now - 1.day
    latest_time = Time.zone.now
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
    self.find_each do |user|
      user.last_daily_track_email = User.random_time_in_last_day
      user.save!
    end
    nil # so doesn't print all users on console
  end

  def self.record_bounce_for_email(email, message)
    user = User.find_user_by_email(email)
    return false if user.nil?

    user.record_bounce(message) if user.email_bounced_at.nil?
    return true
  end

  def self.find_similar_named_users(user)
    User.where('name ILIKE ? AND email_confirmed = ? AND id <> ?',
                user.name, true, user.id).order(:created_at)
  end

  def view_hidden?
    is_admin?
  end

  def view_embargoed?
    is_pro_admin?
  end

  def view_hidden_and_embargoed?
    view_hidden? && view_embargoed?
  end

  def transactions(*associations)
    opts = {}
    opts[:transaction_associations] = associations if associations.any?
    TransactionCalculator.new(self, opts)
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
    return unless saved_change_to_attribute?(:url_name)

    expire_comments
    expire_requests
  end

  def expire_requests
    info_requests.find_each(&:expire)
  end

  def expire_comments
    comments.find_each(&:reindex_request_events)
  end

  def locale
    (super || AlaveteliLocalization.locale).to_s
  end

  def name
    _name = read_attribute(:name)
    if suspended?
      _name = _("{{user_name}} (Account suspended)", :user_name => _name)
    end
    _name
  end

  # When name is changed, also change the url name
  def name=(name)
    write_attribute(:name, name.try(:strip))
    update_url_name
  end

  def update_url_name
    url_name = MySociety::Format.simplify_url_part(read_attribute(:name), 'user', 32)
    # For user with same name as others, add on arbitary numeric identifier
    unique_url_name = url_name
    suffix_num = 2 # as there's already one without numeric suffix
    conditions = id ? ["id <> ?", id] : []
    while !User.where(:url_name => unique_url_name).where(conditions).first.nil?
      unique_url_name = url_name + "_" + suffix_num.to_s
      suffix_num = suffix_num + 1
    end
    self.url_name = unique_url_name
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

  # Does the user magically gain powers as if they owned every request?
  # e.g. Can classify it
  def owns_every_request?
    is_admin?
  end

  def can_admin_roles
    roles.flat_map { |role| Role.grants_and_revokes(role.name.to_sym) }.compact.uniq
  end

  def can_admin_role?(role)
    can_admin_roles.include?(role)
  end

  # Does the user get "(admin)" links on each page on the main site?
  def admin_page_links?
    is_admin?
  end

  # Is it public that they are banned?
  def banned?
    !ban_text.empty?
  end

  def closed?
    closed_at.present?
  end

  def close_and_anonymise
    sha = Digest::SHA1.hexdigest(rand.to_s)

    redact_name! if info_requests.any?

    update(
      name: _('[Name Removed]'),
      email: "#{sha}@invalid",
      url_name: sha,
      about_me: '',
      password: MySociety::Util.generate_token,
      receive_email_alerts: false,
      closed_at: Time.zone.now
    )
  end

  def active?
    !banned? && !closed?
  end

  def suspended?
    !active?
  end

  # Various ways the user can be banned, and text to describe it if failed
  def can_file_requests?
    active? && !exceeded_limit?
  end

  def exceeded_limit?
    # Some users have no limit
    return false if no_limit

    # Batch request users don't have a limit
    return false if can_make_batch_requests?

    # Has the user issued as many as MAX_REQUESTS_PER_USER_PER_DAY requests in the past 24 hours?
    return false if AlaveteliConfiguration.max_requests_per_user_per_day.blank?

    recent_requests =
      InfoRequest.
        where(["user_id = ? AND created_at > now() - '1 day'::interval", id]).
          count

    recent_requests >= AlaveteliConfiguration.max_requests_per_user_per_day
  end

  def next_request_permitted_at
    return nil if no_limit

    n_most_recent_requests =
      InfoRequest.
        where(["user_id = ? AND created_at > now() - '1 day'::interval", id]).
          order('created_at DESC').
            limit(AlaveteliConfiguration.max_requests_per_user_per_day)

    return nil if n_most_recent_requests.size < AlaveteliConfiguration::max_requests_per_user_per_day

    nth_most_recent_request = n_most_recent_requests[-1]
    nth_most_recent_request.created_at + 1.day
  end

  def can_make_followup?
    active?
  end

  def can_make_comments?
    active?
  end

  def can_contact_other_users?
    active?
  end

  def can_fail_html
    if banned?
      text = ban_text.strip
    elsif closed?
      text = _('Account closed at user request')
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
      save!
    end
  end

  def show_profile_photo?
    active? && profile_photo
  end

  def about_me_already_exists?
    return false if about_me.blank?
    self.class.where(:about_me => about_me).where.not(id: id).any?
  end

  # Return about me text for display as HTML
  # TODO: Move this to a view helper
  def get_about_me_for_html_display
    text = about_me.strip
    text = CGI.escapeHTML(text)
    text = MySociety::Format.make_clickable(text, { :contract => 1, :nofollow => true })
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
    self.email_bounced_at = Time.zone.now
    self.email_bounce_message = convert_string_to_utf8(message).string
    save!
  end

  def confirm(save_record = false)
    self.email_confirmed = true
    save! if save_record
  end

  def confirm!
    confirm
    save!
  end

  def should_be_emailed?
    active? && email_confirmed? && receive_email_alerts? && !email_bounced_at
  end

  def indexed_by_search?
    email_confirmed && active?
  end

  def for_admin_column(complete = false)
    if complete
      columns = self.class.content_columns
    else
      columns = self.class.content_columns.map do |c|
        c if %w(created_at updated_at email_confirmed).include?(c.name)
      end.compact
    end
    columns.each do |column|
      yield(column.name.humanize, send(column.name), column.type.to_s, column.name)
    end
  end

  # Notify a user about an info_request_event, allowing the user's preferences
  # to determine how that notification is delivered.
  def notify(info_request_event)
    Notification.create(
      info_request_event: info_request_event,
      frequency: Notification.frequencies[self.notification_frequency],
      user: self
    )
  end

  # Return a timestamp for the next time a user should be sent a daily summary
  def next_daily_summary_time
    summary_time = Time.zone.now.change(self.daily_summary_time)
    summary_time += 1.day if summary_time < Time.zone.now
    summary_time
  end

  def daily_summary_time
    {
      hour: self.daily_summary_hour,
      min: self.daily_summary_minute
    }
  end

  # With what frequency does the user want to be notified?
  def notification_frequency
    if feature_enabled? :notifications, self
      Notification::DAILY
    else
      Notification::INSTANTLY
    end
  end

  # Define an id number for use with the Flipper gem's user-by-user feature
  # flagging. We prefix with the class because features can be enabled for
  # other types of objects (e.g Roles) in the same way and will be stored in
  # the same table. See:
  # https://github.com/jnunemaker/flipper/blob/master/docs/Gates.md
  def flipper_id
    return "User;#{id}"
  end

  private

  def redact_name!
    censor_rules.create!(text: name,
                         replacement: _('[Name Removed]'),
                         last_edit_editor: 'User#close_and_anonymise',
                         last_edit_comment: 'User#close_and_anonymise')
  end

  def set_defaults
    if new_record?
      # make alert emails go out at a random time for each new user, so
      # overall they are spread out throughout the day.
      self.last_daily_track_email = User.random_time_in_last_day
      # Make daily summary emails go out at a random time for each new user
      # too, if it's not already set
      if self.daily_summary_hour.nil? && self.daily_summary_minute.nil?
        random_time = User.random_time_in_last_day
        self.daily_summary_hour = random_time.hour
        self.daily_summary_minute = random_time.min
      end
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

  def setup_pro_account(role)
    return unless role == Role.pro_role
    pro_account || build_pro_account if feature_enabled?(:pro_pricing)
    AlaveteliPro::Access.grant(self)
  end

  def update_pro_account
    pro_account.update_stripe_customer if pro_account
  end

end
