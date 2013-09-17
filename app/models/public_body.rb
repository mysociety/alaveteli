# -*- coding: utf-8 -*-
# == Schema Information
#
# Table name: public_bodies
#
#  id                  :integer          not null, primary key
#  name                :text             not null
#  short_name          :text             not null
#  request_email       :text             not null
#  version             :integer          not null
#  last_edit_editor    :string(255)      not null
#  last_edit_comment   :text             not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  url_name            :text             not null
#  home_page           :text             default(""), not null
#  notes               :text             default(""), not null
#  first_letter        :string(255)      not null
#  publication_scheme  :text             default(""), not null
#  api_key             :string(255)      not null
#  info_requests_count :integer          default(0), not null
#  disclosure_log      :text             default(""), not null
#

require 'csv'
require 'securerandom'
require 'set'

class PublicBody < ActiveRecord::Base
    strip_attributes!

    validates_presence_of :name, :message => N_("Name can't be blank")
    validates_presence_of :url_name, :message => N_("URL name can't be blank")

    validates_uniqueness_of :short_name, :message => N_("Short name is already taken"), :if => Proc.new { |pb| pb.short_name != "" }
    validates_uniqueness_of :name, :message => N_("Name is already taken")

    validate :request_email_if_requestable

    has_many :info_requests, :order => 'created_at desc'
    has_many :track_things, :order => 'created_at desc'
    has_many :censor_rules, :order => 'created_at desc'
    attr_accessor :no_xapian_reindex

    has_tag_string
    before_save :set_api_key, :set_default_publication_scheme

    # Every public body except for the internal admin one is visible
    scope :visible, lambda {
        {
            :conditions => "public_bodies.id <> #{PublicBody.internal_admin_body.id}"
        }
    }

    translates :name, :short_name, :request_email, :url_name, :notes, :first_letter, :publication_scheme

    # Convenience methods for creating/editing translations via forms
    def find_translation_by_locale(locale)
        self.translations.find_by_locale(locale)
    end

    # XXX - Don't like repeating this!
    def calculate_cached_fields(t)
        PublicBody.set_first_letter(t)
        short_long_name = t.name
        short_long_name = t.short_name if t.short_name and !t.short_name.empty?
        t.url_name = MySociety::Format.simplify_url_part(short_long_name, 'body')
    end

    # Set the first letter on a public body or translation
    def PublicBody.set_first_letter(instance)
        unless instance.name.nil? or instance.name.empty?
            # we use a regex to ensure it works with utf-8/multi-byte
            first_letter = instance.name.scan(/^./mu)[0].upcase
            if first_letter != instance.first_letter
                instance.first_letter = first_letter
            end
        end
    end

    def translated_versions
        translations
    end

    def translated_versions=(translation_attrs)
        def skip?(attrs)
            valueless = attrs.inject({}) { |h, (k, v)| h[k] = v if v != '' and k != 'locale'; h } # because we want to fall back to alternative translations where there are empty values
            return valueless.length == 0
        end

        if translation_attrs.respond_to? :each_value    # Hash => updating
            translation_attrs.each_value do |attrs|
                next if skip?(attrs)
                t = translation_for(attrs[:locale]) || PublicBody::Translation.new
                t.attributes = attrs
                calculate_cached_fields(t)
                t.save!
            end
        else                                            # Array => creating
            translation_attrs.each do |attrs|
                next if skip?(attrs)
                new_translation = PublicBody::Translation.new(attrs)
                calculate_cached_fields(new_translation)
                translations << new_translation
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
    before_save(:set_first_letter)
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

    # Can an FOI (etc.) request be made to this body, and if not why not?
    def is_requestable?
        if self.defunct?
            return false
        end
        if self.not_apply?
            return false
        end
        if self.request_email.nil?
            return false
        end
        return !self.request_email.empty? && self.request_email != 'blank'
    end
    # Strict superset of is_requestable?
    def is_followupable?
        if self.request_email.nil?
            return false
        end
        return !self.request_email.empty? && self.request_email != 'blank'
    end
    # Also used as not_followable_reason
    def not_requestable_reason
        if self.defunct?
            return 'defunct'
        elsif self.not_apply?
            return 'not_apply'
        elsif self.request_email.nil? or self.request_email.empty? or self.request_email == 'blank'
            return 'bad_contact'
        else
            raise "requestable_failure_reason called with type that has no reason"
        end
    end

    acts_as_versioned
    self.non_versioned_columns << 'created_at' << 'updated_at' << 'first_letter' << 'api_key'
    self.non_versioned_columns << 'info_requests_count' << 'info_requests_successful_count'
    self.non_versioned_columns << 'info_requests_not_held_count' << 'info_requests_overdue'
    self.non_versioned_columns << 'info_requests_overdue_count'

    class Version
        attr_accessor :created_at

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

    acts_as_xapian :texts => [ :name, :short_name, :notes ],
        :values => [
             [ :created_at_numeric, 1, "created_at", :number ] # for sorting
        ],
        :terms => [ [ :variety, 'V', "variety" ],
                [ :tag_array_for_search, 'U', "tag" ]
        ]
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
    after_update :reindex_requested_from
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
        globalize.write(I18n.locale, :short_name, short_name)
        self[:short_name] = short_name
        self.update_url_name
    end

    def name=(name)
        globalize.write(I18n.locale, :name, name)
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


    # Use tags to describe what type of thing this is
    def type_of_authority(html = false)
        types = []
        first = true
        for tag in self.tags
            if PublicBodyCategories::get().by_tag().include?(tag.name)
                desc = PublicBodyCategories::get().singular_by_tag()[tag.name]
                if first
                    # terrible that Ruby/Rails doesn't have an equivalent of ucfirst
                    # (capitalize shockingly converts later characters to lowercase)
                    desc = desc[0,1].capitalize + desc[1,desc.size]
                    first = false
                end
                if html
                    # XXX this should call proper route helpers, but is in model sigh
                    desc = '<a href="/body/list/' + tag.name + '">' + desc + '</a>'
                end
                types.push(desc)
            end
        end
        if types.size > 0
            ret = types[0, types.size - 1].join(", ")
            if types.size > 1
                ret = ret + " and "
            end
            ret = ret + types[-1]
            return ret.html_safe
        else
            return _("A public authority")
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
        return self.has_tag?('eir_only')
    end
    def law_only_short
        if self.eir_only?
            return "EIR"
        else
            return "FOI"
        end
    end

    # Schools are allowed more time in holidays, so we change some wordings
    def is_school?
        return self.has_tag?('school')
    end

    # The "internal admin" is a special body for internal use.
    def PublicBody.internal_admin_body
        I18n.with_locale(I18n.default_locale) do
            pb = PublicBody.find_by_url_name("internal_admin_authority")
            if pb.nil?
                pb = PublicBody.new(
                 :name => 'Internal admin authority',
                 :short_name => "",
                 :request_email => AlaveteliConfiguration::contact_email,
                 :home_page => "",
                 :notes => "",
                 :publication_scheme => "",
                 :last_edit_editor => "internal_admin",
                 :last_edit_comment => "Made by PublicBody.internal_admin_body"
                )
                pb.save!
            end
            return pb
        end
    end


    class ImportCSVDryRun < StandardError
    end

    # Import from CSV. Just tests things and returns messages if dry_run is true.
    # Returns an array of [array of errors, array of notes]. If there are errors,
    # always rolls back (as with dry_run).
    def self.import_csv(csv, tag, tag_behaviour, dry_run, editor, available_locales = [])
        errors = []
        notes = []
        available_locales = [I18n.default_locale] if available_locales.empty?

        begin
            ActiveRecord::Base.transaction do
                # Use the default locale when retrieving existing bodies; otherwise
                # matching names won't work afterwards, and we'll create new bodies instead
                # of updating them
                bodies_by_name = {}
                set_of_existing = Set.new()
                I18n.with_locale(I18n.default_locale) do
                    bodies = (tag.nil? || tag.empty?) ? PublicBody.find(:all) : PublicBody.find_by_tag(tag)
                    for existing_body in bodies
                        # Hide InternalAdminBody from import notes
                        next if existing_body.id == PublicBody.internal_admin_body.id

                        bodies_by_name[existing_body.name] = existing_body
                        set_of_existing.add(existing_body.name)
                    end
                end

                set_of_importing = Set.new()
                field_names = { 'name'=>1, 'request_email'=>2 }     # Default values in case no field list is given
                line = 0
                CSV.parse(csv) do |row|
                    line = line + 1

                    # Parse the first line as a field list if it starts with '#'
                    if line==1 and row.first.to_s =~ /^#(.*)$/
                        row[0] = row[0][1..-1]  # Remove the # sign on first field
                        row.each_with_index {|field, i| field_names[field] = i}
                        next
                    end

                    fields = {}
                    field_names.each{|name, i| fields[name] = row[i]}

                    name = row[field_names['name']]
                    email = row[field_names['request_email']]
                    next if name.nil?

                    name.strip!
                    email.strip! unless email.nil?

                    if !email.nil? && !email.empty? && !MySociety::Validate.is_valid_email(email)
                        errors.push "error: line #{line.to_s}: invalid email '#{email}' for authority '#{name}'"
                        next
                    end

                    field_list = ['name', 'short_name', 'request_email', 'notes', 'publication_scheme', 'disclosure_log', 'home_page', 'tag_string']

                    if public_body = bodies_by_name[name]   # Existing public body
                        available_locales.each do |locale|
                            I18n.with_locale(locale) do
                                changed = ActiveSupport::OrderedHash.new
                                field_list.each do |field_name|
                                    localized_field_name = (locale.to_s == I18n.default_locale.to_s) ? field_name : "#{field_name}.#{locale}"
                                    localized_value = field_names[localized_field_name] && row[field_names[localized_field_name]]

                                    # Tags are a special case, as we support adding to the field, not just setting a new value
                                    if localized_field_name == 'tag_string'
                                        if localized_value.nil?
                                            localized_value = tag unless tag.empty?
                                        else
                                            if tag_behaviour == 'add'
                                                localized_value = "#{localized_value} #{tag}" unless tag.empty?
                                                localized_value = "#{localized_value} #{public_body.tag_string}"
                                            end
                                        end
                                    end

                                    if !localized_value.nil? and public_body.send(field_name) != localized_value
                                        changed[field_name] = "#{public_body.send(field_name)}: #{localized_value}"
                                        public_body.send("#{field_name}=", localized_value)
                                    end
                                end

                                unless changed.empty?
                                    notes.push "line #{line.to_s}: updating authority '#{name}' (locale: #{locale}):\n\t#{changed.to_json}"
                                    public_body.last_edit_editor = editor
                                    public_body.last_edit_comment = 'Updated from spreadsheet'
                                    public_body.save!
                                end
                            end
                        end
                    else # New public body
                        public_body = PublicBody.new(:name=>"", :short_name=>"", :request_email=>"")
                        available_locales.each do |locale|
                            I18n.with_locale(locale) do
                                changed = ActiveSupport::OrderedHash.new
                                field_list.each do |field_name|
                                    localized_field_name = (locale.to_s == I18n.default_locale.to_s) ? field_name : "#{field_name}.#{locale}"
                                    localized_value = field_names[localized_field_name] && row[field_names[localized_field_name]]

                                    if localized_field_name == 'tag_string' and tag_behaviour == 'add'
                                        localized_value = "#{localized_value} #{tag}" unless tag.empty?
                                    end

                                    if !localized_value.nil? and public_body.send(field_name) != localized_value
                                        changed[field_name] = localized_value
                                        public_body.send("#{field_name}=", localized_value)
                                    end
                                end

                                unless changed.empty?
                                    notes.push "line #{line.to_s}: creating new authority '#{name}' (locale: #{locale}):\n\t#{changed.to_json}"
                                    public_body.publication_scheme = public_body.publication_scheme || ""
                                    public_body.last_edit_editor = editor
                                    public_body.last_edit_comment = 'Created from spreadsheet'
                                    public_body.save!
                                end
                            end
                        end
                    end

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

    # Returns all public bodies (except for the internal admin authority) as csv
    def self.export_csv
        public_bodies = PublicBody.visible.find(:all, :order => 'url_name',
                                              :include => [:translations, :tags])
        FasterCSV.generate() do |csv|
            csv << [
                    'Name',
                    'Short name',
                    # deliberately not including 'Request email'
                    'URL name',
                    'Tags',
                    'Home page',
                    'Publication scheme',
                    'Disclosure log',
                    'Notes',
                    'Created at',
                    'Updated at',
                    'Version',
            ]
            public_bodies.each do |public_body|
                # Skip bodies we use only for site admin
                next if public_body.has_tag?('site_administration')
                csv << [
                    public_body.name,
                    public_body.short_name,
                    # DO NOT include request_email (we don't want to make it
                    # easy to spam all authorities with requests)
                    public_body.url_name,
                    public_body.tag_string,
                    public_body.calculated_home_page,
                    public_body.publication_scheme,
                    public_body.disclosure_log,
                    public_body.notes,
                    public_body.created_at,
                    public_body.updated_at,
                    public_body.version,
                ]
            end
        end
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

    # Returns nil if configuration variable not set
    def override_request_email
        e = AlaveteliConfiguration::override_all_public_body_request_emails
        e if e != ""
    end

    def request_email
        if override_request_email
            override_request_email
        else
            read_attribute(:request_email)
        end
    end

    # Domain name of the request email
    def request_email_domain
        return PublicBody.extract_domain_from_email(self.request_email)
    end

    # Return the domain part of an email address, canonicalised and with common
    # extra UK Government server name parts removed.
    def PublicBody.extract_domain_from_email(email)
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

    after_save(:purge_in_cache)
    def purge_in_cache
        self.info_requests.each {|x| x.purge_in_cache}
    end

    def for_admin_column
        self.class.content_columns.map{|c| c unless %w(name last_edit_comment).include?(c.name)}.compact.each do |column|
            yield(column.human_name, self.send(column.name), column.type.to_s, column.name)
        end
    end

    # Return data for the 'n' public bodies with the highest (or
    # lowest) number of requests, but only returning data for those
    # with at least 'minimum_requests' requests.
    def self.get_request_totals(n, highest, minimum_requests)
        ordering = "info_requests_count"
        ordering += " DESC" if highest
        where_clause = "info_requests_count >= #{minimum_requests}"
        public_bodies = PublicBody.order(ordering).where(where_clause).limit(n)
        public_bodies.reverse! if highest
        y_values = public_bodies.map { |pb| pb.info_requests_count }
        return {
            'public_bodies' => public_bodies,
            'y_values' => y_values,
            'y_max' => y_values.max}
    end

    # Return data for the 'n' public bodies with the highest (or
    # lowest) score according to the metric of the value in 'column'
    # divided by the total number of requests, expressed as a
    # percentage.  This only returns data for those public bodies with
    # at least 'minimum_requests' requests.
    def self.get_request_percentages(column, n, highest, minimum_requests)
        total_column = "info_requests_count"
        ordering = "y_value"
        ordering += " DESC" if highest
        y_value_column = "(cast(#{column} as float) / #{total_column})"
        where_clause = "#{total_column} >= #{minimum_requests} AND #{column} IS NOT NULL"
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
            'y_max' => 100}
    end

    private

    def request_email_if_requestable
        # Request_email can be blank, meaning we don't have details
        if self.is_requestable?
            unless MySociety::Validate.is_valid_email(self.request_email)
                errors.add(:request_email, "Request email doesn't look like a valid email address")
            end
        end
    end
end
