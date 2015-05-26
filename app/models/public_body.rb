# -*- encoding : utf-8 -*-
# == Schema Information
# Schema version: 20131024114346
#
# Table name: public_bodies
#
#  id                                     :integer          not null, primary key
#  name                                   :text             not null
#  short_name                             :text             default(""), not null
#  request_email                          :text             not null
#  version                                :integer          not null
#  last_edit_editor                       :string(255)      not null
#  last_edit_comment                      :text             not null
#  created_at                             :datetime         not null
#  updated_at                             :datetime         not null
#  url_name                               :text             not null
#  home_page                              :text             default(""), not null
#  notes                                  :text             default(""), not null
#  first_letter                           :string(255)      not null
#  publication_scheme                     :text             default(""), not null
#  api_key                                :string(255)      not null
#  info_requests_count                    :integer          default(0), not null
#  disclosure_log                         :text             default(""), not null
#  info_requests_successful_count         :integer
#  info_requests_not_held_count           :integer
#  info_requests_overdue_count            :integer
#  info_requests_visible_classified_count :integer
#

require 'csv'
require 'securerandom'
require 'set'

class PublicBody < ActiveRecord::Base
    include AdminColumn

    @non_admin_columns = %w(name last_edit_comment)

    strip_attributes!

    validates_presence_of :name, :message => N_("Name can't be blank")
    validates_presence_of :url_name, :message => N_("URL name can't be blank")

    validates_uniqueness_of :short_name, :message => N_("Short name is already taken"), :allow_blank => true
    validates_uniqueness_of :url_name, :message => N_("URL name is already taken")
    validates_uniqueness_of :name, :message => N_("Name is already taken")

    validate :request_email_if_requestable

    has_many :info_requests, :order => 'created_at desc'
    has_many :track_things, :order => 'created_at desc'
    has_many :censor_rules, :order => 'created_at desc'
    attr_accessor :no_xapian_reindex

    has_tag_string

    before_save :set_api_key,
                :set_default_publication_scheme,
                :set_first_letter
    after_save :purge_in_cache
    after_update :reindex_requested_from

    # Every public body except for the internal admin one is visible
    scope :visible, lambda {
        {
            :conditions => "public_bodies.id <> #{PublicBody.internal_admin_body.id}"
        }
    }

    translates :name, :short_name, :request_email, :url_name, :notes, :first_letter, :publication_scheme

    # Default fields available for importing from CSV, in the format
    # [field_name, 'short description of field (basic html allowed)']
    cattr_accessor :csv_import_fields do
        [
            ['name', '(i18n)<strong>Existing records cannot be renamed</strong>'],
            ['short_name', '(i18n)'],
            ['request_email', '(i18n)'],
            ['notes', '(i18n)'],
            ['publication_scheme', '(i18n)'],
            ['disclosure_log', '(i18n)'],
            ['home_page', ''],
            ['tag_string', '(tags separated by spaces)'],
        ]
    end

    acts_as_xapian :texts => [ :name, :short_name, :notes ],
        :values => [
             [ :created_at_numeric, 1, "created_at", :number ] # for sorting
        ],
        :terms => [ [ :variety, 'V', "variety" ],
                [ :tag_array_for_search, 'U', "tag" ]
        ]

    acts_as_versioned
    self.non_versioned_columns << 'created_at' << 'updated_at' << 'first_letter' << 'api_key'
    self.non_versioned_columns << 'info_requests_count' << 'info_requests_successful_count'
    self.non_versioned_columns << 'info_requests_count' << 'info_requests_visible_classified_count'
    self.non_versioned_columns << 'info_requests_not_held_count' << 'info_requests_overdue'
    self.non_versioned_columns << 'info_requests_overdue_count'

    include Translatable

    # Public: Search for Public Bodies whose name, short_name, request_email or
    # tags contain the given query
    #
    # query  - String to query the searchable fields
    # locale - String to specify the language of the seach query
    #          (default: I18n.locale)
    #
    # Returns an ActiveRecord::Relation
    def self.search(query, locale = I18n.locale)
        locale = locale.to_s.gsub('-', '_') # Clean the locale string

        sql = <<-SQL
            (
              lower(public_body_translations.name) like lower('%'||?||'%')
              OR lower(public_body_translations.short_name) like lower('%'||?||'%')
              OR lower(public_body_translations.request_email) like lower('%'||?||'%' )
              OR lower(has_tag_string_tags.name) like lower('%'||?||'%' )
            )
            AND has_tag_string_tags.model_id = public_bodies.id
            AND has_tag_string_tags.model = 'PublicBody'
            AND (public_body_translations.locale = ?)
        SQL

        PublicBody.joins(:translations, :tags).
                     where([sql, query, query, query, query, locale]).
                       uniq
    end

    # TODO: - Don't like repeating this!
    def calculate_cached_fields(t)
        PublicBody.set_first_letter(t)
        short_long_name = t.name
        short_long_name = t.short_name if t.short_name and !t.short_name.empty?
        t.url_name = MySociety::Format.simplify_url_part(short_long_name, 'body')
    end

    # Set the first letter on a public body or translation
    def self.set_first_letter(instance)
        unless instance.name.nil? or instance.name.empty?
            # we use a regex to ensure it works with utf-8/multi-byte
            first_letter = Unicode.upcase instance.name.scan(/^./mu)[0]
            if first_letter != instance.first_letter
                instance.first_letter = first_letter
            end
        end
    end

    def set_default_publication_scheme
      # Make sure publication_scheme gets the correct default value.
      # (This would work automatically, were publication_scheme not a translated attribute)
      self.publication_scheme = "" if self.publication_scheme.nil?
    end

    def set_api_key
      self.api_key = SecureRandom.base64(33) if self.api_key.nil?
    end

    # like find_by_url_name but also search historic url_name if none found
    def self.find_by_url_name_with_historic(name)
        found = PublicBody.find(:all,
                                :conditions => ["public_body_translations.url_name=?", name],
                                :joins => :translations,
                                :readonly => false)
        # If many bodies are found (usually because the url_name is the same across
        # locales) return any of them
        return found.first if found.size >= 1

        # If none found, then search the history of short names
        old = PublicBody::Version.find_all_by_url_name(name)
        # Find unique public bodies in it
        old = old.map { |x| x.public_body_id }
        old = old.uniq
        # Maybe return the first one, so we show something relevant,
        # rather than throwing an error?
        raise "Two bodies with the same historical URL name: #{name}" if old.size > 1
        return unless old.size == 1
        # does acts_as_versioned provide a method that returns the current version?
        return PublicBody.find(old.first)
    end

    # Set the first letter, which is used for faster queries
    def set_first_letter
        PublicBody.set_first_letter(self)
    end

    # If tagged "not_apply", then FOI/EIR no longer applies to authority at all
    def not_apply?
        return self.has_tag?('not_apply')
    end
    # If tagged "defunct", then the authority no longer exists at all
    def defunct?
        return self.has_tag?('defunct')
    end

    # Can an FOI (etc.) request be made to this body?
    def is_requestable?
        has_request_email? && !defunct? && !not_apply?
    end

    # Strict superset of is_requestable?
    def is_followupable?
        has_request_email?
    end

    def has_request_email?
       !request_email.blank? && request_email != 'blank'
    end

    # Also used as not_followable_reason
    def not_requestable_reason
        if self.defunct?
            return 'defunct'
        elsif self.not_apply?
            return 'not_apply'
        elsif !has_request_email?
            return 'bad_contact'
        else
            raise "not_requestable_reason called with type that has no reason"
        end
    end

    def special_not_requestable_reason?
        self.defunct? || self.not_apply?
    end


    class Version

        def last_edit_comment_for_html_display
            text = self.last_edit_comment.strip
            text = CGI.escapeHTML(text)
            text = MySociety::Format.make_clickable(text)
            text = text.gsub(/\n/, '<br>')
            return text
        end

        def compare(previous = nil)
          if previous.nil?
            yield([])
          else
            v = self
            changes = self.class.content_columns.inject([]) {|memo, c|
              unless %w(version last_edit_editor last_edit_comment updated_at).include?(c.name)
                from = previous.send(c.name)
                to = self.send(c.name)
                memo << { :name => c.human_name, :from => from, :to => to } if from != to
              end
              memo
            }
            changes.each do |change|
              yield(change)
            end
          end
        end
    end

    def created_at_numeric
        # format it here as no datetime support in Xapian's value ranges
        return self.created_at.strftime("%Y%m%d%H%M%S")
    end
    def variety
        return "authority"
    end

    # if the URL name has changed, then all requested_from: queries
    # will break unless we update index for every event for every
    # request linked to it
    def reindex_requested_from
        if self.changes.include?('url_name')
            for info_request in self.info_requests

                for info_request_event in info_request.info_request_events
                    info_request_event.xapian_mark_needs_index
                end
            end
        end
    end

    # When name or short name is changed, also change the url name
    def short_name=(short_name)
        globalize.write(Globalize.locale, :short_name, short_name)
        self[:short_name] = short_name
        self.update_url_name
    end

    def name=(name)
        globalize.write(Globalize.locale, :name, name)
        self[:name] = name
        self.update_url_name
    end

    def update_url_name
        self.url_name = MySociety::Format.simplify_url_part(self.short_or_long_name, 'body')
    end

    # Return the short name if present, or else long name
    def short_or_long_name
        if self.short_name.nil? || self.short_name.empty?   # 'nil' can happen during construction
            self.name.nil? ? "" : self.name
        else
            self.short_name
        end
    end

    # Guess home page from the request email, or use explicit override, or nil
    # if not known.
    def calculated_home_page
        if home_page && !home_page.empty?
            home_page[URI::regexp(%w(http https))] ? home_page : "http://#{home_page}"
        elsif request_email_domain
            "http://www.#{request_email_domain}"
        end
    end

    # Are all requests to this body under the Environmental Information Regulations?
    def eir_only?
        has_tag?('eir_only')
    end

    def law_only_short
        eir_only? ? 'EIR' : 'FOI'
    end

    # Schools are allowed more time in holidays, so we change some wordings
    def is_school?
        has_tag?('school')
    end

    def site_administration?
        has_tag?('site_administration')
    end

    # The "internal admin" is a special body for internal use.
    def self.internal_admin_body
        # Use find_by_sql to avoid the search being specific to a
        # locale, since url_name is a translated field:
        sql = "SELECT * FROM public_bodies WHERE url_name = 'internal_admin_authority'"
        matching_pbs = PublicBody.find_by_sql sql
        case
        when matching_pbs.empty? then
            I18n.with_locale(I18n.default_locale) do
                PublicBody.create!(:name => 'Internal admin authority',
                                   :short_name => "",
                                   :request_email => AlaveteliConfiguration::contact_email,
                                   :home_page => "",
                                   :notes => "",
                                   :publication_scheme => "",
                                   :last_edit_editor => "internal_admin",
                                   :last_edit_comment => "Made by PublicBody.internal_admin_body")
            end
        when matching_pbs.length == 1 then
            matching_pbs[0]
        else
            raise "Multiple public bodies (#{matching_pbs.length}) found with url_name 'internal_admin_authority'"
        end
    end

    class ImportCSVDryRun < StandardError
    end

    # Import from a string in CSV format.
    # Just tests things and returns messages if dry_run is true.
    # Returns an array of [array of errors, array of notes]. If there
    # are errors, always rolls back (as with dry_run).
    def self.import_csv(csv, tag, tag_behaviour, dry_run, editor, available_locales = [])
        tmp_csv = nil
        Tempfile.open('alaveteli') do |f|
            f.write csv
            tmp_csv = f
        end
        PublicBody.import_csv_from_file(tmp_csv.path, tag, tag_behaviour, dry_run, editor, available_locales)
    end

    # Import from a CSV file.
    # Just tests things and returns messages if dry_run is true.
    # Returns an array of [array of errors, array of notes]. If there
    # are errors, always rolls back (as with dry_run).
    def self.import_csv_from_file(csv_filename, tag, tag_behaviour, dry_run, editor, available_locales = [])
        errors = []
        notes = []
        begin
            ActiveRecord::Base.transaction do
                # Use the default locale when retrieving existing bodies; otherwise
                # matching names won't work afterwards, and we'll create new bodies instead
                # of updating them
                bodies_by_name = {}
                set_of_existing = Set.new
                internal_admin_body_id = PublicBody.internal_admin_body.id
                I18n.with_locale(I18n.default_locale) do
                    bodies = (tag.nil? || tag.empty?) ? PublicBody.find(:all, :include => :translations) : PublicBody.find_by_tag(tag)
                    for existing_body in bodies
                        # Hide InternalAdminBody from import notes
                        next if existing_body.id == internal_admin_body_id

                        bodies_by_name[existing_body.name] = existing_body
                        set_of_existing.add(existing_body.name)
                    end
                end

                set_of_importing = Set.new
                # Default values in case no field list is given
                field_names = { 'name' => 1, 'request_email' => 2 }
                line = 0

                import_options = {:field_names => field_names,
                                  :available_locales => available_locales,
                                  :tag => tag,
                                  :tag_behaviour => tag_behaviour,
                                  :editor => editor,
                                  :notes => notes,
                                  :errors => errors }

                CSV.foreach(csv_filename) do |row|
                    line = line + 1

                    # Parse the first line as a field list if it starts with '#'
                    if line==1 and row.first.to_s =~ /^#(.*)$/
                        row[0] = row[0][1..-1]  # Remove the # sign on first field
                        row.each_with_index {|field, i| field_names[field] = i}
                        next
                    end

                    fields = {}
                    field_names.each{ |name, i| fields[name] = row[i] }

                    yield line, fields if block_given?

                    name = row[field_names['name']]
                    email = row[field_names['request_email']]
                    next if name.nil?

                    name.strip!
                    email.strip! unless email.nil?

                    if !email.nil? && !email.empty? && !MySociety::Validate.is_valid_email(email)
                        errors.push "error: line #{line.to_s}: invalid email '#{email}' for authority '#{name}'"
                        next
                    end

                    public_body = bodies_by_name[name] || PublicBody.new(:name => "",
                                                                         :short_name => "",
                                                                         :request_email => "")

                    public_body.import_values_from_csv_row(row, line, name, import_options)
                    set_of_importing.add(name)
                end

                # Give an error listing ones that are to be deleted
                deleted_ones = set_of_existing - set_of_importing
                if deleted_ones.size > 0
                    notes.push "Notes: Some " + tag + " bodies are in database, but not in CSV file:\n    " + Array(deleted_ones).sort.join("\n    ") + "\nYou may want to delete them manually.\n"
                end

                # Rollback if a dry run, or we had errors
                if dry_run or errors.size > 0
                    raise ImportCSVDryRun
                end
            end
        rescue ImportCSVDryRun
            # Ignore
        end

        return [errors, notes]
    end

    def self.localized_csv_field_name(locale, field_name)
        (locale.to_s == I18n.default_locale.to_s) ? field_name : "#{field_name}.#{locale}"
    end


    # import values from a csv row (that may include localized columns)
    def import_values_from_csv_row(row, line, name, options)
        is_new = new_record?
        edit_info = if is_new
            { :action => "creating new authority",
              :comment => 'Created from spreadsheet' }
        else
            { :action => "updating authority",
              :comment => 'Updated from spreadsheet' }
        end
        locales = options[:available_locales]
        locales = [I18n.default_locale] if locales.empty?
        locales.each do |locale|
            I18n.with_locale(locale) do
                changed = set_locale_fields_from_csv_row(is_new, locale, row, options)
                unless changed.empty?
                    options[:notes].push "line #{ line }: #{ edit_info[:action] } '#{ name }' (locale: #{ locale }):\n\t#{ changed.to_json }"
                    self.last_edit_comment = edit_info[:comment]
                    self.publication_scheme = publication_scheme || ""
                    self.last_edit_editor = options[:editor]

                    begin
                        save!
                    rescue ActiveRecord::RecordInvalid
                        errors.full_messages.each do |msg|
                            options[:errors].push "error: line #{ line }: #{ msg } for authority '#{ name }'"
                        end
                        next
                    end
                end
            end
        end
    end

    # Sets attribute values for a locale from a csv row
    def set_locale_fields_from_csv_row(is_new, locale, row, options)
        changed = ActiveSupport::OrderedHash.new
        csv_field_names = options[:field_names]
        csv_import_fields.each do |field_name, field_notes|
            localized_field_name = self.class.localized_csv_field_name(locale, field_name)
            column = csv_field_names[localized_field_name]
            value = column && row[column]
            # Tags are a special case, as we support adding to the field, not just setting a new value
            if field_name == 'tag_string'
                new_tags = [value, options[:tag]].select{ |new_tag| !new_tag.blank? }
                if new_tags.empty?
                    value = nil
                else
                    value = new_tags.join(" ")
                    value = "#{value} #{tag_string}"if options[:tag_behaviour] == 'add'
                end

            end

            if value and read_attribute_value(field_name, locale) != value
                if is_new
                    changed[field_name] = value
                else
                    changed[field_name] = "#{read_attribute_value(field_name, locale)}: #{value}"
                end
                assign_attributes({ field_name => value })
            end
        end
        changed
    end

    # Does this user have the power of FOI officer for this body?
    def is_foi_officer?(user)
        user_domain = user.email_domain
        our_domain = self.request_email_domain

        if user_domain.nil? or our_domain.nil?
            return false
        end

        return our_domain == user_domain
    end
    def foi_officer_domain_required
        return self.request_email_domain
    end

    def request_email
        if AlaveteliConfiguration::override_all_public_body_request_emails.blank? || read_attribute(:request_email).blank?
            read_attribute(:request_email)
        else
            AlaveteliConfiguration::override_all_public_body_request_emails
        end
    end

    # Domain name of the request email
    def request_email_domain
        return PublicBody.extract_domain_from_email(self.request_email)
    end

    # Return the domain part of an email address, canonicalised and with common
    # extra UK Government server name parts removed.
    def self.extract_domain_from_email(email)
        email =~ /@(.*)/
        if $1.nil?
            return nil
        end

        # take lower case
        ret = $1.downcase

        # remove special email domains for UK Government addresses
        ret.sub!(".gsi.", ".")
        ret.sub!(".x.", ".")
        ret.sub!(".pnn.", ".")

        return ret
    end

    def reverse_sorted_versions
        self.versions.sort { |a,b| b.version <=> a.version }
    end
    def sorted_versions
        self.versions.sort { |a,b| a.version <=> b.version }
    end

    def has_notes?
        return !self.notes.nil? && self.notes != ""
    end
    def notes_as_html
        self.notes
    end

    def notes_without_html
        # assume notes are reasonably behaved HTML, so just use simple regexp on this
        @notes_without_html ||= (self.notes.nil? ? '' : self.notes.gsub(/<\/?[^>]*>/, ""))
    end

    def json_for_api
        return {
            :id => self.id,
            :url_name => self.url_name,
            :name => self.name,
            :short_name => self.short_name,
            # :request_email  # we hide this behind a captcha, to stop people doing bulk requests easily
            :created_at => self.created_at,
            :updated_at => self.updated_at,
            # don't add the history as some edit comments contain sensitive information
            # :version, :last_edit_editor, :last_edit_comment
            :home_page => self.calculated_home_page,
            :notes => self.notes,
            :publication_scheme => self.publication_scheme,
            :tags => self.tag_array,
        }
    end

    def purge_in_cache
        self.info_requests.each {|x| x.purge_in_cache}
    end

    def self.where_clause_for_stats(minimum_requests, total_column)
        # When producing statistics for public bodies, we want to
        # exclude any that are tagged with 'test' - we use a
        # sub-select to find the IDs of those public bodies.
        test_tagged_query = "SELECT model_id FROM has_tag_string_tags" \
            " WHERE model = 'PublicBody' AND name = 'test'"
        "#{total_column} >= #{minimum_requests} AND id NOT IN (#{test_tagged_query})"
    end

    # Return data for the 'n' public bodies with the highest (or
    # lowest) number of requests, but only returning data for those
    # with at least 'minimum_requests' requests.
    def self.get_request_totals(n, highest, minimum_requests)
        ordering = "info_requests_count"
        ordering += " DESC" if highest
        where_clause = where_clause_for_stats minimum_requests, 'info_requests_count'
        public_bodies = PublicBody.order(ordering).where(where_clause).limit(n)
        public_bodies.reverse! if highest
        y_values = public_bodies.map { |pb| pb.info_requests_count }
        return {
            'public_bodies' => public_bodies,
            'y_values' => y_values,
            'y_max' => y_values.max,
            'totals' => y_values}
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
        public_bodies = PublicBody.select("*, #{y_value_column} AS y_value").order(ordering).where(where_clause).limit(n)
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
        return {
            'public_bodies' => public_bodies,
            'y_values' => y_values,
            'cis_below' => cis_below,
            'cis_above' => cis_above,
            'y_max' => 100,
            'totals' => original_totals}
    end
    def self.popular_bodies(locale)
        # get some example searches and public bodies to display
        # either from config, or based on a (slow!) query if not set
        body_short_names = AlaveteliConfiguration::frontpage_publicbody_examples.split(/\s*;\s*/)
        locale_condition = 'public_body_translations.locale = ?'
        underscore_locale = locale.gsub '-', '_'
        conditions = [locale_condition, underscore_locale]
        bodies = []
        I18n.with_locale(locale) do
            if body_short_names.empty?
                # This is too slow
                bodies = visible.find(:all,
                    :order => "info_requests_count desc",
                    :limit => 32,
                    :conditions => conditions,
                    :joins => :translations
                )
            else
                conditions[0] += " and public_bodies.url_name in (?)"
                conditions << body_short_names
                bodies = find(:all, :conditions => conditions, :joins => :translations)
            end
        end
        return bodies
    end

    private

    # Read an attribute value (without using locale fallbacks if the attribute is translated)
    def read_attribute_value(name, locale)
      if self.class.translates.include?(name.to_sym)
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
        if self.is_requestable?
            unless MySociety::Validate.is_valid_email(self.request_email)
                errors.add(:request_email, "Request email doesn't look like a valid email address")
            end
        end
    end
end
