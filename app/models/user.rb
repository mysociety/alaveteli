# == Schema Information
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
#  last_daily_track_email            :datetime
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
#  receive_user_messages             :boolean          default(TRUE), not null
#  user_messages_count               :integer          default(0), not null
#  status_update_count               :integer          default(0), not null
#  last_sign_in_at                   :datetime
#

class User < ApplicationRecord
  include Rails.application.routes.url_helpers
  include LinkToHelper

  include Taggable

  include AlaveteliFeatures::Helpers
  include AlaveteliPro::PhaseCounts

  include User::Authentication
  include User::InternalAdmin
  include User::LimitedProfile
  include User::LoginToken
  include User::OneTimePassword
  include User::Slug
  include User::SpreadableAlerts
  include User::Survey
  include User::Unused

  DEFAULT_CONTENT_LIMITS = {
    info_requests: AlaveteliConfiguration.max_requests_per_user_per_day,
    comments: AlaveteliConfiguration.max_requests_per_user_per_day,
    user_messages: AlaveteliConfiguration.max_requests_per_user_per_day
  }.freeze

  cattr_accessor :content_limits, default: DEFAULT_CONTENT_LIMITS

  rolify before_add: :setup_pro_account,
         after_add: :assign_role_features,
         after_remove: :assign_role_features
  strip_attributes allow_empty: true

  admin_columns include: [:user_messages_count],
                exclude: [:otp_secret_key, :url_name]

  attr_accessor :no_xapian_reindex

  has_many :info_requests,
           -> { order(created_at: :desc) },
           inverse_of: :user,
           dependent: :destroy
  has_many :info_request_events,
           -> { reorder(created_at: :desc) },
           through: :info_requests
  has_many :embargoes,
           inverse_of: :user,
           through: :info_requests
  has_many :outgoing_messages,
           inverse_of: :user,
           through: :info_requests
  has_many :draft_info_requests,
           -> { order(created_at: :desc) },
           inverse_of: :user,
           dependent: :destroy
  has_many :user_info_request_sent_alerts,
           inverse_of: :user,
           dependent: :destroy
  has_many :post_redirects,
           -> { order(created_at: :desc) },
           inverse_of: :user,
           dependent: :destroy
  has_many :track_things,
           -> { order(created_at: :desc) },
           inverse_of: :tracking_user,
           foreign_key: 'tracking_user_id',
           dependent: :destroy
  has_many :citations,
           -> { order(created_at: :desc) },
           inverse_of: :user,
           dependent: :destroy
  has_many :comments,
           -> { order(created_at: :desc) },
           inverse_of: :user,
           dependent: :destroy
  has_many :public_body_change_requests,
           -> { order(created_at: :desc) },
           inverse_of: :user,
           dependent: :destroy
  has_one :profile_photo,
          inverse_of: :user,
          dependent: :destroy
  has_many :censor_rules,
           -> { order(created_at: :desc) },
           inverse_of: :user,
           dependent: :destroy
  has_many :info_request_batches,
           -> { order(created_at: :desc) },
           inverse_of: :user,
           dependent: :destroy
  has_many :draft_info_request_batches,
           -> { order(created_at: :desc) },
           inverse_of: :user,
           dependent: :destroy,
           class_name: 'AlaveteliPro::DraftInfoRequestBatch'
  has_many :request_classifications,
           inverse_of: :user,
           dependent: :destroy
  has_one :pro_account,
          inverse_of: :user,
          dependent: :destroy
  has_many :request_summaries,
           inverse_of: :user,
           dependent: :destroy,
           class_name: 'AlaveteliPro::RequestSummary'
  has_many :notifications,
           inverse_of: :user,
           dependent: :destroy
  has_many :track_things_sent_emails,
           inverse_of: :user,
           dependent: :destroy
  has_many :track_things_sent_emails,
           dependent: :destroy
  has_many :announcements,
           inverse_of: :user
  has_many :announcement_dismissals,
           inverse_of: :user,
           dependent: :destroy
  has_many :memberships, class_name: 'Project::Membership'
  has_many :projects, through: :memberships do
    def owner
      unscope(:joins).joins(:owner_membership)
    end

    def contributor
      unscope(:joins).joins(:contributor_memberships)
    end
  end

  has_many :sign_ins,
           class_name: 'User::SignIn',
           inverse_of: :user,
           dependent: :destroy

  has_many :user_messages,
           -> { order(created_at: :desc) },
           inverse_of: :user,
           dependent: :destroy

  has_many :email_histories,
           -> { order(changed_at: :desc) },
           class_name: 'User::EmailHistory',
           inverse_of: :user,
           dependent: :destroy

  scope :active, -> { not_banned.not_closed }
  scope :banned, -> { where.not(ban_text: '') }
  scope :not_banned, -> { where(ban_text: '') }
  scope :closed, -> { where.not(closed_at: nil) }
  scope :not_closed, -> { where(closed_at: nil) }

  validates_presence_of :email, message: _('Please enter your email address')
  validates_presence_of :name, message: _('Please enter your name')

  validates_length_of :about_me,
                      maximum: 500,
                      message: _('Please keep it shorter than 500 characters')

  validates :email,
            uniqueness: { case_sensitive: false,
                          message: _('This email is already in use') }

  validate :email_and_name_are_valid

  after_update :update_pro_account
  after_update :reindex_referencing_models, :invalidate_cached_pages,
               unless: :no_xapian_reindex

  acts_as_xapian texts: [:name, :about_me],
                 values: [
                   [:created_at_numeric, 1, 'created_at', :number] # for sorting
                 ],
                 terms: [[:variety, 'V', 'variety']],
                 if: :indexed_by_search?

  def self.search(query)
    where(<<~SQL, query: query)
      lower(users.name) LIKE lower('%'||:query||'%') OR
      lower(users.email) LIKE lower('%'||:query||'%') OR
      lower(users.about_me) LIKE lower('%'||:query||'%')
    SQL
  end

  def self.pro
    with_role(:pro)
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

  def self.authenticate_from_session(session)
    return unless session[:user_id]

    find_by(id: session[:user_id], login_token: session[:user_login_token])
  end

  # Case-insensitively find a user from their email
  def self.find_user_by_email(email)
    return nil if email.blank?

    where('lower(email) = lower(?)', email.strip).first
  end

  # Should the user be kept logged into their own account
  # if they follow a /c/ redirect link belonging to another user?
  def self.stay_logged_in_on_redirect?(user)
    user&.is_admin?
  end

  def self.record_bounce_for_email(email, message)
    user = User.find_user_by_email(email)
    return false if user.nil?

    user.record_bounce(message) if user.email_bounced_at.nil?
    true
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
    'user'
  end

  # requested_by: and commented_by: search queries also need updating after save
  def reindex_referencing_models
    return unless saved_change_to_attribute?(:url_name)

    expire_comments
    expire_requests
  end

  def expire_requests
    InfoRequestExpireJob.perform_later(self, :info_requests)
  end

  def expire_comments
    comments.find_each(&:reindex_request_events)
  end

  def invalidate_cached_pages
    NotifyCacheJob.perform_later(self)
  end

  def locale
    (super || AlaveteliLocalization.locale).to_s
  end

  def name
    _name = read_attribute(:name)
    if suspended?
      _name = _('{{user_name}} (Account suspended)', user_name: _name)
    end
    _name
  end

  # When name is changed, also change the url name
  def name=(name)
    write_attribute(:name, name.try(:strip))
  end

  def previous_names
    outgoing_messages.unscope(:order).
      distinct(:from_name).
      where.not(from_name: read_attribute(:name)).
      pluck(:from_name)
  end

  def safe_previous_names
    outgoing_messages.map(&:safe_from_name).uniq - [read_attribute(:name)]
  end

  # For use in to/from in email messages
  def name_and_email
    MailHandler.address_from_name_and_email(name, email)
  end

  # Returns list of requests which the user hasn't described (and last
  # changed more than a day ago)
  def get_undescribed_requests
    info_requests.
      where(awaiting_description: true).
      where("#{ InfoRequest.last_event_time_clause } < ?", 1.day.ago)
  end

  # Does the user magically gain powers as if they owned every request?
  # e.g. Can classify it
  def owns_every_request?
    is_admin?
  end

  def admin?
    is_admin? || is_pro_admin?
  end

  def can_admin_roles
    roles.
      flat_map { |role| Role.grants_and_revokes(role.name.to_sym) }.
      compact.
      uniq
  end

  def can_admin_role?(role)
    can_admin_roles.include?(role)
  end

  # Does the user get "(admin)" links on each page on the main site?
  def admin_page_links?
    is_admin?
  end

  def banned?
    ban_text.present?
  end

  def close
    close!
  rescue ActiveRecord::RecordInvalid
    false
  end

  def close!
    update!(closed_at: Time.zone.now, receive_email_alerts: false)
  end

  def closed?
    closed_at.present?
  end

  def erase
    erase!
  rescue ActiveRecord::RecordInvalid
    false
  end

  def erase!
    raise ActiveRecord::RecordInvalid unless closed?

    sha = Digest::SHA1.hexdigest(rand.to_s)

    transaction do
      slugs.destroy_all
      sign_ins.destroy_all
      email_histories.destroy_all
      profile_photo&.destroy!

      outgoing_messages.update!(
        from_name: _('[Name Removed]')
      )

      update!(
        name: _('[Name Removed]'),
        email: "#{sha}@invalid",
        url_name: sha,
        about_me: '',
        password: MySociety::Util.generate_token
      )
    end
  end

  def anonymise!
    return if info_requests.none? && comments.none?

    current_name = read_attribute(:name)
    [current_name, *previous_names].each do |name|
      censor_rules.create!(text: name,
                           replacement: _('[Name Removed]'),
                           last_edit_editor: 'User#anonymise!',
                           last_edit_comment: 'User#anonymise!')
    end
  end

  def close_and_anonymise
    transaction do
      close!
      anonymise!
      erase!
    end
  end

  def active?
    !banned? && !closed?
  end

  def suspended?
    !active?
  end

  def prominence
    return 'hidden' if banned?
    return 'backpage' if closed?
    return 'backpage' unless email_confirmed?

    'normal'
  end

  # Various ways the user can be banned, and text to describe it if failed
  def can_file_requests?
    active? && !exceeded_limit?(:info_requests)
  end

  def can_make_followup?
    active?
  end

  def can_make_comments?
    return false unless active?
    return true if no_limit? || is_admin? || is_pro_admin?

    !exceeded_limit?(:comments) &&
      !Comment.exceeded_creation_rate?(comments)
  end

  def can_contact_other_users?
    active? && !exceeded_limit?(:user_messages)
  end

  def exceeded_limit?(content)
    return false if no_limit?
    return false if can_make_batch_requests?
    return false if content_limit(content).blank?

    # Has the User created too much of the content in the past 24 hours?
    recent_content =
      content.to_s.classify.constantize.
        where(["user_id = ? AND created_at > now() - '1 day'::interval", id]).
        count

    recent_content >= content_limit(content)
  end

  def next_request_permitted_at
    return nil if no_limit

    request_limit = content_limit(:info_requests)
    n_most_recent_requests =
      InfoRequest.
        where(["user_id = ? AND created_at > now() - '1 day'::interval", id]).
          order(created_at: :desc).
            limit(request_limit)

    return nil if n_most_recent_requests.size < request_limit

    nth_most_recent_request = n_most_recent_requests[-1]
    nth_most_recent_request.created_at + 1.day
  end

  def can_fail_html
    if banned?
      text = ban_text.strip
    elsif closed?
      text = _('Account closed at user request')
    else
      raise 'Unknown reason for ban'
    end
    text = CGI.escapeHTML(text)
    text = MySociety::Format.make_clickable(text, contract: 1)
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
    active? && profile_photo.present? && !limited_profile?
  end

  def show_about_me?
    active? && about_me.present? && !limited_profile?
  end

  def about_me_already_exists?
    return false if about_me.blank?

    self.class.where(about_me: about_me).where.not(id: id).any?
  end

  # Return about me text for display as HTML
  # TODO: Move this to a view helper
  def get_about_me_for_html_display
    text = about_me.strip
    text = CGI.escapeHTML(text)
    text = MySociety::Format.make_clickable(text, contract: 1, nofollow: true)
    text = text.gsub(/\n/, '<br>')
    text.html_safe
  end

  def json_for_api
    {
      id: id,
      url_name: url_name,
      name: name,
      ban_text: ban_text,
      about_me: about_me
      # :profile_photo => self.profile_photo # ought to have this, but too hard to get URL out for now
      # created_at / updated_at we only show the year on the main page for privacy reasons, so don't put here
    }
  end

  def record_bounce(message)
    update!(
      email_bounced_at: Time.zone.now,
      email_bounce_message: convert_string_to_utf8(message).string
    )
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
    email_confirmed && active? && info_requests.any?
  end

  # Notify a user about an info_request_event, allowing the user's preferences
  # to determine how that notification is delivered.
  def notify(info_request_event)
    Notification.create(
      info_request_event: info_request_event,
      frequency: Notification.frequencies[notification_frequency],
      user: self
    )
  end

  # Return a timestamp for the next time a user should be sent a daily summary
  def next_daily_summary_time
    summary_time = Time.zone.now.change(daily_summary_time)
    summary_time += 1.day if summary_time < Time.zone.now
    summary_time
  end

  def daily_summary_time
    { hour: daily_summary_hour,
      min: daily_summary_minute }
  end

  # With what frequency does the user want to be notified?
  def notification_frequency
    if features.enabled?(:notifications)
      Notification::DAILY
    else
      Notification::INSTANTLY
    end
  end

  def features
    # Will return enabled and disabled features. Call #enabled? to see the
    # current state
    AlaveteliFeatures.features.with_actor(self)
  end

  def features=(new_features)
    features.assign_features(new_features)
  end

  # Define an id number for use with the Flipper gem's user-by-user feature
  # flagging. We prefix with the class because features can be enabled for
  # other types of objects (e.g Roles) in the same way and will be stored in
  # the same table. See:
  # https://github.com/jnunemaker/flipper/blob/master/docs/Gates.md
  def flipper_id
    "User;#{id}"
  end

  def cached_urls
    [
      user_path(self)
    ]
  end

  def info_request_count_changed
    xapian_mark_needs_index
  end

  def record_sign_in(*args)
    sign_ins.create(*args)
    touch(:last_sign_in_at)
  end

  private

  def email_and_name_are_valid
    if email != "" && !MySociety::Validate.is_valid_email(email)
      errors.add(:email, _("Please enter a valid email address"))
    end
    if MySociety::Validate.is_valid_email(name)
      errors.add(:name, _("Please enter your name, not your email address, in the name field."))
    end
  end

  def assign_role_features(_role)
    features.assign_role_features
  end

  def setup_pro_account(role)
    return unless role == Role.pro_role

    pro_account || build_pro_account if feature_enabled?(:pro_pricing)
  end

  def update_pro_account
    pro_account.update_stripe_customer if pro_account
  end

  def content_limit(content)
    content_limits[content]
  end
end
