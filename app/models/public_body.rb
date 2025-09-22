# == Schema Information
#
# Table name: public_bodies
#
#  id                                     :integer          not null, primary key
#  version                                :integer          not null
#  last_edit_editor                       :string           not null
#  last_edit_comment                      :text
#  created_at                             :datetime         not null
#  updated_at                             :datetime         not null
#  home_page                              :text
#  api_key                                :string           not null
#  info_requests_count                    :integer          default(0), not null
#  info_requests_successful_count         :integer
#  info_requests_not_held_count           :integer
#  info_requests_overdue_count            :integer
#  info_requests_visible_classified_count :integer
#  info_requests_visible_count            :integer          default(0), not null
#  name                                   :text
#  short_name                             :text
#  request_email                          :text
#  url_name                               :text
#  first_letter                           :string
#  publication_scheme                     :text
#  disclosure_log                         :text
#

require 'securerandom'
require 'set'
require 'confidence_intervals'

class PublicBody < ApplicationRecord
  include Rails.application.routes.url_helpers
  include LinkToHelper

  include Categorisable
  include Taggable
  include Notable

  include PublicBody::CalculatedHomePage
  include PublicBody::CsvImport
  include PublicBody::FoiOfficerAccess

  admin_columns exclude: %i[name last_edit_editor]

  def self.admin_title
    'Authority'
  end

  attr_accessor :no_xapian_reindex

  # Set to 0 to prevent application of the not_many_requests tag
  cattr_accessor :not_many_public_requests_size,
                 instance_writer: false,
                 default: 5

  # Any PublicBody tagged with any of the follow tags won't be returned in the
  # batch authority search results or batch category UI
  cattr_accessor :batch_excluded_tags,
                 instance_accessor: false,
                 default: %w[not_apply defunct]

  has_many :info_requests,
           -> { order(created_at: :desc) },
           inverse_of: :public_body
  has_many :track_things,
           -> { order(created_at: :desc) },
           inverse_of: :public_body,
           dependent: :destroy
  has_many :censor_rules,
           -> { order(created_at: :desc) },
           inverse_of: :public_body,
           dependent: :destroy
  has_many :track_things_sent_emails,
           -> { order(created_at: :desc) },
           inverse_of: :public_body,
           dependent: :destroy
  has_many :public_body_change_requests,
           -> { order(created_at: :desc) },
           inverse_of: :public_body,
           dependent: :destroy
  has_many :draft_info_requests,
           -> { order(created_at: :desc) },
           inverse_of: :public_body

  has_and_belongs_to_many :info_request_batches,
                          inverse_of: :public_bodies
  has_and_belongs_to_many :draft_info_request_batches,
                          class_name: 'AlaveteliPro::DraftInfoRequestBatch',
                          inverse_of: :public_bodies

  validates_presence_of :name, message: N_("Name can't be blank")
  validates_presence_of :url_name, message: N_("URL name can't be blank")
  validates_presence_of :last_edit_editor,
                        message: N_("Last edit editor can't be blank")

  validates :request_email,
            not_nil: { message: N_("Request email can't be nil") }

  validates_uniqueness_of :short_name,
                          message: N_("Short name is already taken"),
                          allow_blank: true
  validates_uniqueness_of :url_name, message: N_("URL name is already taken")
  validates_uniqueness_of :name, message: N_("Name is already taken")

  validates :last_edit_editor,
            length: { maximum: 255,
                      too_long: N_("Last edit editor can't be longer than " \
                                   "255 characters") }

  validate :request_email_if_requestable

  before_save :set_api_key!, unless: :api_key

  after_save :update_auto_applied_tags

  after_update :reindex_requested_from, :invalidate_cached_pages,
               unless: :no_xapian_reindex

  # Every public body except for the internal admin one is visible
  scope :visible, -> { where("public_bodies.id <> #{ PublicBody.internal_admin_body.id }") }

  acts_as_versioned
  acts_as_xapian texts: [:name, :short_name, :notes_as_string],
                 values: [
                   # for sorting
                   [:created_at_numeric, 1, "created_at", :number]
                 ],
                 terms: [
                   [:name_for_search, 'N', 'name'],
                   [:variety, 'V', "variety"],
                   [:tag_array_for_search, 'U', "tag"]
                 ],
                 eager_load: [:translations]

  strip_attributes allow_empty: false, except: %i[request_email]
  strip_attributes allow_empty: true, only: %i[request_email]

  translates :name, :short_name, :request_email, :url_name, :first_letter,
             :publication_scheme, :disclosure_log

  # Cannot be grouped at top as it depends on the `translates` macro
  include Translatable

  # Cannot be grouped at top as it depends on the `translates` macro
  include PublicBodyDerivedFields

  # Cannot be grouped at top as it depends on the `translates` macro
  class Translation
    include PublicBodyDerivedFields
    strip_attributes allow_empty: false, except: %i[request_email]
    strip_attributes allow_empty: true, only: %i[request_email]
  end

  non_versioned_columns << 'created_at' << 'updated_at' << 'first_letter' << 'api_key'
  non_versioned_columns << 'info_requests_count' << 'info_requests_successful_count'
  non_versioned_columns << 'info_requests_count' << 'info_requests_visible_classified_count'
  non_versioned_columns << 'info_requests_not_held_count' << 'info_requests_overdue'
  non_versioned_columns << 'info_requests_overdue_count' << 'info_requests_visible_count'

  # Cannot be defined directly under `include` statements as this is opening
  # the PublicBody::Version class dynamically defined by  the
  # `acts_as_versioned` macro.
  #
  # TODO: acts_as_versioned accepts an extend parameter [1] so these methods
  # could be extracted to a module:
  #
  #    acts_as_versioned :extend => PublicBodyVersionExtensions
  #
  # This includes the module in both the parent class (PublicBody) and the
  # Version class (PublicBody::Version), so the behaviour is slightly
  # different to opening up PublicBody::Version.
  #
  # We could add an `extend_version_class` option pretty trivially by
  # following the pattern for the existing `extend` option.
  #
  # [1] https://github.com/technoweenie/acts_as_versioned/blob/63b1fc8529/lib/acts_as_versioned.rb#L98-L118
  class Version
    before_save :copy_translated_attributes

    def copy_translated_attributes
      public_body.attributes.each do |name, value|
        if public_body.translated?(name) &&
           !public_body.non_versioned_columns.include?(name)
          send("#{name}=", value)
        end
      end
    end

    def last_edit_comment_for_html_display
      text = last_edit_comment.strip
      text = CGI.escapeHTML(text)
      text = MySociety::Format.make_clickable(text)
      text.gsub(/\n/, '<br>')
    end

    def compare(previous = nil)
      if previous.nil?
        changes = []
      else
        v = self
        changes = self.class.content_columns.inject([]) { |memo, c|
          unless %w(version
                    last_edit_editor
                    last_edit_comment
                    created_at
                    updated_at).include?(c.name)
            from = previous.send(c.name)
            to = send(c.name)
            memo << { name: c.name.humanize,
                      from: from,
                      to: to } if from != to
          end
          memo
        }
      end
      if block_given?
        changes.each do |change|
          yield(change)
        end
      end
      changes
    end

    def editor
      User.find_by(url_name: last_edit_editor)
    end
  end

  # Public: Search for Public Bodies whose name, short_name, request_email or
  # tags contain the given query
  #
  # query  - String to query the searchable fields
  # locale - String to specify the language of the search query
  #          (default: AlaveteliLocalization.locale)
  #
  # Returns an ActiveRecord::Relation
  def self.search(query, locale = AlaveteliLocalization.locale)
    sql = <<-SQL
    (
      lower(public_body_translations.name) like lower('%'||?||'%')
      OR lower(public_body_translations.short_name) like lower('%'||?||'%')
      OR lower(public_body_translations.request_email) like lower('%'||?||'%' )
      OR lower(has_tag_string_tags.name) like lower('%'||?||'%' )
    )
    AND has_tag_string_tags.model_id = public_bodies.id
    AND has_tag_string_tags.model_type = 'PublicBody'
    AND (public_body_translations.locale = ?)
    SQL

    PublicBody.joins(:translations, :tags).
      where([sql, query, query, query, query, locale]).
      uniq
  end

  def self.with_domain(domain)
    return none unless domain

    with_translations(AlaveteliLocalization.locale).
      where("lower(public_body_translations.request_email) " \
            "like lower('%'||?||'%')", domain).
        merge(PublicBody::Translation.order(:name))
  end

  def set_api_key
    set_api_key! if api_key.nil?
  end

  def set_api_key!
    self.api_key = SecureRandom.base64(33)
  end

  def self.find_by_name(name)
    find_by(name: name)
  end

  def self.find_by_url_name(url_name)
    find_by(url_name: url_name)
  end

  # like find_by_url_name but also search historic url_name if none found
  def self.find_by_url_name_with_historic(name)
    # If many bodies are found (usually because the url_name is the same
    # across locales) return any of them.
    found = joins(:translations).
      where("public_body_translations.url_name = ?", name).
      readonly(false).
      first

    return found if found

    # If none found, then search the history of short names and find unique
    # public bodies in it
    old = PublicBody::Version.
      where(url_name: name).
      distinct.
      pluck(:public_body_id)

    # Maybe return the first one, so we show something relevant,
    # rather than throwing an error?
    if old.size > 1
      raise "Two bodies with the same historical URL name: #{name}"
    end
    return unless old.size == 1

    # does acts_as_versioned provide a method that returns the current version?
    PublicBody.find(old.first)
  end

  def self.without_request_email
    joins(:translations).
      where(public_body_translations: { request_email: '' }).
      not_defunct
  end

  def self.with_request_email
    joins(:translations).
      where.not(public_body_translations: { request_email: '' })
  end

  # If tagged "not_apply", then FOI/EIR no longer applies to authority at all
  # and the site will not accept further requests for them
  def not_apply?
    has_tag?('not_apply')
  end

  scope :foi_applies, -> { without_tag('not_apply') }

  # If tagged "foi_no", then the authority is not subject to FOI law but
  # requests may still be made through the site (e.g. they may have agreed to
  # respond to requests on a voluntary basis)
  # This will apply in all cases if the site has been configured not to state
  # that authorities have a legal obligation
  def not_subject_to_law?
    has_tag?('foi_no') || !AlaveteliConfiguration.authority_must_respond
  end

  # If tagged "defunct", then the authority no longer exists at all
  def defunct?
    has_tag?('defunct')
  end

  scope :not_defunct, -> { without_tag('defunct') }

  # Are all requests to this body under the Environmental Information
  # Regulations?
  def eir_only?
    has_tag?('eir_only')
  end

  def site_administration?
    has_tag?('site_administration')
  end

  # Can an FOI (etc.) request be made to this body?
  def is_requestable?
    has_request_email? && !defunct? && !not_apply?
  end

  scope :is_requestable, -> { with_request_email.not_defunct.foi_applies }

  # Strict superset of is_requestable?
  def is_followupable?
    has_request_email?
  end

  def has_request_email?
    !request_email.blank? && request_email != 'blank'
  end

  # Also used as not_followable_reason
  def not_requestable_reason
    if defunct?
      'defunct'
    elsif not_apply?
      'not_apply'
    elsif !has_request_email?
      'bad_contact'
    else
      raise "not_requestable_reason called with type that has no reason"
    end
  end

  def special_not_requestable_reason?
    defunct? || not_apply?
  end

  def created_at_numeric
    # format it here as no datetime support in Xapian's value ranges
    created_at.strftime("%Y%m%d%H%M%S")
  end

  def variety
    "authority"
  end

  def legislations
    @legislations ||= Legislation.for_public_body(self)
  end

  def legislation
    legislations.first
  end

  # The "internal admin" is a special body for internal use.
  def self.internal_admin_body
    matching_pbs = AlaveteliLocalization.
      with_locale(AlaveteliLocalization.default_locale) do
      default_scoped.where(url_name: 'internal_admin_authority')
    end

    if matching_pbs.empty?
      # "internal admin" exists but has the wrong default locale - fix & return
      if (invalid_locale = PublicBody::Translation.
                             find_by_url_name('internal_admin_authority'))
        found_pb = PublicBody.find(invalid_locale.public_body_id)
        AlaveteliLocalization.
          with_locale(AlaveteliLocalization.default_locale) do
          found_pb.name = "Internal admin authority"
          found_pb.request_email = AlaveteliConfiguration.contact_email
          found_pb.save!
        end
        found_pb
      else
        AlaveteliLocalization.
          with_locale(AlaveteliLocalization.default_locale) do
          default_scoped.
            create!(name: 'Internal admin authority',
                    short_name: "",
                    request_email: AlaveteliConfiguration.contact_email,
                    home_page: nil,
                    publication_scheme: nil,
                    last_edit_editor: "internal_admin",
                    last_edit_comment:                       "Made by PublicBody.internal_admin_body")
        end
      end
    elsif matching_pbs.length == 1
      matching_pbs[0]
    else
      raise "Multiple public bodies (#{matching_pbs.length}) found with url_name 'internal_admin_authority'"
    end
  end

  def request_email
    if AlaveteliConfiguration.override_all_public_body_request_emails.blank? ||
       read_attribute(:request_email).blank?
      read_attribute(:request_email)
    else
      AlaveteliConfiguration.override_all_public_body_request_emails
    end
  end

  # Domain name of the request email
  def request_email_domain
    PublicBody.extract_domain_from_email(request_email)
  end

  alias foi_officer_domain_required request_email_domain

  # Return the canonicalised domain part of an email address
  #
  # TODO: Extract to library class
  def self.extract_domain_from_email(email)
    email =~ /@(.*)/
    $1.nil? ? nil : $1.downcase
  end

  def notes
    Note.sort(all_notes)
  end

  def notes_as_string
    notes.map(&:to_plain_text).join(' ')
  end

  def has_notes?
    notes.present?
  end

  def json_for_api
    {
      id: id,
      url_name: url_name,
      name: name,
      short_name: short_name,
      # :request_email  # we hide this behind a captcha, to stop people
      # doing bulk requests easily
      created_at: created_at,
      updated_at: updated_at,
      # don't add the history as some edit comments contain sensitive
      # information
      # :version, :last_edit_editor, :last_edit_comment
      home_page: calculated_home_page,
      notes: notes_as_string,
      publication_scheme: publication_scheme.to_s,
      disclosure_log: disclosure_log.to_s,
      tags: tag_array,
      info: {
        requests_count: info_requests_count,
        requests_successful_count: info_requests_successful_count,
        requests_not_held_count: info_requests_not_held_count,
        requests_overdue_count: info_requests_overdue_count,
        requests_visible_classified_count:           info_requests_visible_classified_count
      }
    }
  end

  def expire_requests
    InfoRequestExpireJob.perform_later(self, :info_requests)
  end

  def self.where_clause_for_stats(minimum_requests, total_column)
    # When producing statistics for public bodies, we want to
    # exclude any that are tagged with 'test' - we use a
    # sub-select to find the IDs of those public bodies.
    test_tagged_query = "SELECT model_id FROM has_tag_string_tags" \
      " WHERE model_type = 'PublicBody' AND name = 'test'"
    "#{total_column} >= #{minimum_requests} " \
    "AND id NOT IN (#{test_tagged_query})"
  end

  # Return data for the 'n' public bodies with the highest (or
  # lowest) number of requests, but only returning data for those
  # with at least 'minimum_requests' requests.
  def self.get_request_totals(n, highest, minimum_requests)
    ordering = "info_requests_visible_count"
    ordering += " DESC" if highest
    where_clause = where_clause_for_stats minimum_requests,
                  'info_requests_visible_count'
    public_bodies = PublicBody.order(ordering).
                      where(where_clause).
                        limit(n).
                          to_a
    public_bodies.reverse! if highest
    y_values = public_bodies.map(&:info_requests_visible_count)
    {
      'public_bodies' => public_bodies,
      'y_values' => y_values,
      'y_max' => y_values.max,
    'totals' => y_values }
  end

  # Return data for the 'n' public bodies with the highest (or
  # lowest) score according to the metric of the value in 'column'
  # divided by the total number of requests, expressed as a
  # percentage.  This only returns data for those public bodies with
  # at least 'minimum_requests' requests.
  def self.get_request_percentages(column, n, highest, minimum_requests)
    total_column = "info_requests_visible_classified_count"
    ordering = "y_value"
    ordering += " DESC" if highest
    y_value_column = "(cast(#{column} as float) / #{total_column})"
    where_clause = where_clause_for_stats minimum_requests, total_column
    where_clause += " AND #{column} IS NOT NULL"
    public_bodies = PublicBody.select("*, #{y_value_column} AS y_value").
                                order(ordering).
                                  where(where_clause).
                                    limit(n).
                                      to_a
    public_bodies.reverse! if highest
    y_values = public_bodies.map { |pb| pb.y_value.to_f }

    original_values = public_bodies.map { |pb| pb.send(column) }
    # If these are all nil, then probably the values have never
    # been set; some have to be set by a rake task.  In that case,
    # just return nil:
    return nil unless original_values.any? { |ov| !ov.nil? }

    original_totals = public_bodies.map { |pb| pb.send(total_column) }
    # Calculate confidence intervals, as offsets from the proportion:
    cis_below = []
    cis_above = []
    original_totals.each_with_index.map { |total, i|
      lower_ci, higher_ci = ci_bounds original_values[i], total, 0.05
      cis_below.push(y_values[i] - lower_ci)
      cis_above.push(higher_ci - y_values[i])
    }
    # Turn the y values and confidence interval offsets into
    # percentages:
    [y_values, cis_below, cis_above].each { |l|
      l.map! { |v| 100 * v }
    }
    {
      'public_bodies' => public_bodies,
      'y_values' => y_values,
      'cis_below' => cis_below,
      'cis_above' => cis_above,
      'y_max' => 100,
    'totals' => original_totals }
  end

  def self.popular_bodies(locale)
    # get some example searches and public bodies to display
    # either from config, or based on a (slow!) query if not set
    body_short_names = AlaveteliConfiguration.
                         frontpage_publicbody_examples.
                           split(/\s*;\s*/)
    underscore_locale = locale.gsub '-', '_'
    bodies = []
    AlaveteliLocalization.with_locale(locale) do
      if body_short_names.empty?
        # This is too slow
        bodies = visible.
                  where('public_body_translations.locale = ?',
                         underscore_locale).
                    order(info_requests_visible_count: :desc).
                      limit(32).
                        joins(:translations)
      else
        bodies = where("public_body_translations.locale = ?
                        AND public_body_translations.url_name in (?)",
                        underscore_locale, body_short_names).
                  joins(:translations)
      end
    end
    bodies
  end

  class << self
    alias original_with_tag with_tag
  end

  def self.with_tag(tag)
    return all if tag.size == 1 || tag.nil? || tag == 'all'

    if tag == 'other'
      tags = PublicBody.category_list.distinct.
        where.not(category_tag: [nil, '', 'other']).
        pluck(:category_tag)
      where.not("EXISTS(#{tag_search_sql(tags)})")
    else
      original_with_tag(tag)
    end
  end

  def self.with_query(query, tag)
    like_query = "%#{query}%"
    has_first_letter = tag.size == 1

    underscore_locale = AlaveteliLocalization.locale
    underscore_default_locale = AlaveteliLocalization.default_locale
    where_parameters = {
      locale: underscore_locale,
      query: like_query,
      first_letter: tag
    }

    if AlaveteliConfiguration.public_body_list_fallback_to_default_locale
      # Unfortunately, when we might fall back to the
      # default locale, this is a rather complex query:
      if DatabaseCollation.supports?(underscore_locale)
        select_sql = %Q(public_bodies.*, COALESCE(current_locale.name, default_locale.name) COLLATE "#{underscore_locale}" AS display_name)
      else
        select_sql = %Q(public_bodies.*, COALESCE(current_locale.name, default_locale.name) AS display_name)
      end

      select(select_sql).
        joins(
          "LEFT OUTER JOIN public_body_translations as current_locale ON " \
          "(public_bodies.id = current_locale.public_body_id AND " \
          "current_locale.locale = '#{sanitize_sql(underscore_locale)}')"
        ).
        joins(
          "LEFT OUTER JOIN public_body_translations as default_locale ON " \
          "(public_bodies.id = default_locale.public_body_id AND " \
          "default_locale.locale = " \
          "'#{sanitize_sql(underscore_default_locale)}')"
        ).
        where("(#{get_public_body_list_translated_condition('current_locale', has_first_letter)}) OR " \
              "(#{get_public_body_list_translated_condition('default_locale', has_first_letter)}) ", where_parameters).
        where('COALESCE(current_locale.name, default_locale.name) IS NOT NULL').
        order(:display_name)
    else
      # The simpler case where we're just searching in the current locale:
      where_condition = get_public_body_list_translated_condition('public_body_translations', has_first_letter, true)

      if DatabaseCollation.supports?(underscore_locale)
        where(where_condition, where_parameters).
          joins(:translations).
          order(Arel.sql(%Q(public_body_translations.name COLLATE "#{underscore_locale}")))
      else
        where(where_condition, where_parameters).
          joins(:translations).
            merge(PublicBody::Translation.order(:name))
      end
    end
  end

  # This method updates the count columns of the PublicBody that
  # store the number of "not held", "to some extent successful" and
  # "both visible and classified" requests.
  def update_counter_cache
    success_states = %w(successful partially_successful)

    mappings = {
      info_requests_not_held_count: { awaiting_description: false,
                                      described_state: 'not_held' },
      info_requests_successful_count: { awaiting_description: false,
                                        described_state: success_states },
      info_requests_visible_classified_count: { awaiting_description: false },
      info_requests_visible_count: {}
    }

    info_request_scope = InfoRequest.where(public_body_id: id).is_searchable

    updated_counts = mappings.each_with_object({}) do |(column, params), memo|
      memo[column] = info_request_scope.where(params).count
    end

    update_columns(updated_counts)
  end

  def questions
    PublicBodyQuestion.fetch(self)
  end

  def cached_urls
    [
      public_body_path(self),
      list_public_bodies_path,
      '^/body/list'
    ]
  end

  def info_request_count_changed
    update_not_many_requests_tag
  end

  private

  # If the url_name has changed, then all requested_from: queries will break
  # unless we update index for every event for every request linked to it.
  def reindex_requested_from
    expire_requests if saved_change_to_attribute?(:url_name)
  end

  def invalidate_cached_pages
    NotifyCacheJob.perform_later(self)
  end

  # Read an attribute value (without using locale fallbacks if the
  # attribute is translated)
  def read_attribute_value(name, locale)
    if self.class.translated?(name.to_sym)
      if globalize.stash.contains?(locale, name)
        globalize.stash.read(locale, name)
      else
        translation_for(locale).send(name)
      end
    else
      send(name)
    end
  end

  def request_email_if_requestable
    # Request_email can be blank, meaning we don't have details
    if is_requestable?
      unless MySociety::Validate.is_valid_email(request_email)
        errors.add(:request_email,
                   "Request email doesn't look like a valid email address")
      end
    end
  end

  def name_for_search
    name.downcase
  end

  def self.get_public_body_list_translated_condition(table, has_first_letter=false, locale=nil)
    result = "(upper(#{table}.name) LIKE upper(:query)" \
      " OR upper(#{table}.short_name) LIKE upper(:query))"
    result += " AND #{table}.first_letter = :first_letter" if has_first_letter
    result += " AND #{table}.locale = :locale" if locale
    result
  end
  private_class_method :get_public_body_list_translated_condition

  def update_auto_applied_tags
    update_missing_email_tag
    update_not_many_requests_tag
  end

  def update_missing_email_tag
    if missing_email? && !defunct?
      add_tag_if_not_already_present('missing_email')
    else
      remove_tag('missing_email')
    end
  end

  def missing_email?
    !has_request_email?
  end

  def update_not_many_requests_tag
    if is_requestable? && not_many_public_requests?
      add_tag_if_not_already_present('not_many_requests')
    else
      remove_tag('not_many_requests')
    end
  end

  def not_many_public_requests?
    info_requests.is_searchable.size < not_many_public_requests_size
  end
end
