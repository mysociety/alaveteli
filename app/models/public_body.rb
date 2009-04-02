# == Schema Information
# Schema version: 74
#
# Table name: public_bodies
#
#  id                 :integer         not null, primary key
#  name               :text            not null
#  short_name         :text            not null
#  request_email      :text            not null
#  version            :integer         not null
#  last_edit_editor   :string(255)     not null
#  last_edit_comment  :text            not null
#  created_at         :datetime        not null
#  updated_at         :datetime        not null
#  url_name           :text            not null
#  home_page          :text            default(""), not null
#  notes              :text            default(""), not null
#  first_letter       :string(255)     not null
#  publication_scheme :text            default(""), not null
#

# models/public_body.rb:
# A public body, from which information can be requested.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: public_body.rb,v 1.139 2009-04-02 15:33:11 francis Exp $

require 'csv'
require 'set'

class PublicBody < ActiveRecord::Base
    strip_attributes!

    validates_presence_of :name
    validates_presence_of :url_name

    validates_uniqueness_of :short_name, :if => Proc.new { |pb| pb.short_name != "" }
    validates_uniqueness_of :name
    
    has_many :info_requests, :order => 'created_at desc'
    has_many :public_body_tags
    has_many :track_things, :order => 'created_at desc'

    def self.categories_with_headings
        [
            "Miscellaneous",
                [ "other", "Miscellaneous", "miscellaneous" ],
            "Central government",
                [ "department", "Ministerial departments", "a ministerial department" ], 
                [ "non_ministerial_department", "Non-ministerial departments", "a non-ministerial department" ], 
                [ "executive_agency", "Executive agencies", "an executive agency" ], 
                [ "government_office", "Government offices for the regions", "a government office for the regions" ],  
                [ "advisory_committee", "Advisory committees", "an advisory committee" ],
                [ "awc", "Agricultural wages committees", "an agriculatural wages committee" ],
                [ "adhac", "Agricultural dwelling house advisory committees", "an agriculatural dwelling house advisory committee" ],
                [ "newdeal", "New Deal for Communities partnership", "a New Deal for Communities partnership" ],
            "Local and regional",
                [ "local_council", "Local councils", "a local council" ],
                [ "parish_council", "Town and Parish councils", "a town/parish council"], 
                [ "housing_association", "Housing associations", "a housing association"],
                [ "almo", "Housing ALMOs", "a housing ALMO"],
                [ "municipal_bank", "Municipal bank", "a municipal bank"],
                [ "nsbody", "North/south bodies", "a north/south body"],
                [ "pbo", "Professional buying organisations", "a professional buying organisation"],
                [ "regional_assembly", "Regional assemblies", "a regional assembly"], 
                [ "rda", "Regional development agencies", "a regional development agency" ], 
              "Education",
                [ "university", "Universities", "a university" ],
                [ "university_college", "University colleges", "a university college" ], 
                [ "cambridge_college", "Cambridge colleges", "a Cambridge college" ],
                [ "durham_college", "Durham colleges", "a Durham college" ],
                [ "oxford_college", "Oxford colleges", "an Oxford college or permanent private hall" ],
                [ "york_college", "York colleges", "a college of the University of York" ],
                [ "university_owned_company", "University owned companies", "a university owned company" ],
                [ "hei", "Higher education institutions", "a higher educational institution" ],
                [ "fei", "Further education institutions", "a further educational institution" ],
                [ "research_council", "Research councils", "a research council" ],
                [ "lib_board", "Education and library boards", "an education and library board" ],
            "Environment",
                [ "npa", "National park authorities", "a national park authority" ], 
                [ "rpa", "Regional park authorities", "a national park authoriy" ],
                [ "sea_fishery_committee", "Sea fisheries committees", "a sea fisheries committee" ], 
                [ "watercompanies", "Water companies", "a water company" ],
                [ "idb", "Internal drainage boards", "an internal drainage board" ],
                [ "rfdc", "Regional flood defence committees", "a regional flood defence committee" ],
                [ "wda", "Waste disposal authorities", "a waste disposal authority" ],
                [ "zoo", "Zoos", "a zoo" ],
            "Health",
                [ "nhstrust", "NHS trusts", "an NHS trust" ],
                [ "pct", "Primary care trusts", "a primary care trust" ],
                [ "nhswales", "NHS in Wales", "part of the NHS in Wales" ],
                [ "nhsni", "NHS in Northern Ireland", "part of the NHS in Northern Ireland" ],
                [ "hscr", "Health / social care", "Relating to health / social care" ],
                [ "pha", "Port health authorities", "a port health authority"],
                [ "sha", "Strategic health authorities", "a strategic health authority" ],
                [ "specialha", "Special health authorities", "a special health authority" ],
            "Media and culture",
                [ "media", "Media", "a media organisation" ],
                [ "rcc", "Cultural consortia", "a cultural consortium"],
                [ "museum", "Museums and galleries", "a museum or gallery" ],
            "Military and security services",
                [ "military_college", "Military colleges", "a military college" ],
                [ "security_services", "Security services", "a security services body" ],
            "Emergency services and the courts",
                [ "police", "Police forces", "a police force" ], 
                [ "police_authority", "Police authorities", "a police authority" ], 
                [ "dpp", "District policing partnerships", "a district policing partnership" ],
                [ "fire_service", "Fire and rescue services", "a fire and rescue service" ],
                [ "prob_board", "Probation boards", "a probation board" ],
                [ "rules_committee", "Rules commitees", "a rules committee" ],
                [ "tribunal", "Tribunals", "a tribunal"],
            "Transport",
                [ "npte", "Passenger transport executives", "a passenger transport executive" ],
                [ "port_authority", "Port authorities", "a port authority" ],
                [ "scp", "Safety Camera Partnerships", "a safety camera partnership" ],
                [ "srp", "Safer Roads Partnership", "a safer roads partnership" ]
        ]
    end
    def self.categories_with_description
        self.categories_with_headings.select() { |a| a.instance_of?(Array) } 
    end
    def self.categories
        self.categories_with_description.map() { |a| a[0] }
    end
    def self.categories_by_tag
        Hash[*self.categories_with_description.map() { |a| a[0..1] }.flatten]
    end
    def self.category_singular_by_tag
        Hash[*self.categories_with_description.map() { |a| [a[0],a[2]] }.flatten]
    end

    # like find_by_url_name but also search historic url_name if none found
    def self.find_by_urlname(name)
        found = PublicBody.find_all_by_url_name(name)
        return found.first if found.size == 1
        # Shouldn't we just make url_name unique?
        raise "Two bodies with the same URL name: #{name}" if found.size > 1
        # If none found, then search the history of short names
        old = PublicBody::Version.find_all_by_url_name(name)
        # :conditions => [ "id in (select public_body_id from public_body_versions where url_name = ?)", name ])
        # Maybe return the first one, so we show something relevant,
        # rather than throwing an error?
        raise "Two bodies with the same historical URL name: #{name}" if old.size > 1
        return unless old.size == 1
        # does acts_as_versioned provide a method that returns the current version?
        return PublicBody.find(old.first.public_body_id)
    end


    # Set the first letter, which is used for faster queries
    before_save(:set_first_letter)
    def set_first_letter
        self.first_letter = self.name[0,1].upcase
    end

    def validate
        # Request_email can be blank, meaning we don't have details
        if self.is_requestable?
            unless MySociety::Validate.is_valid_email(self.request_email)
                errors.add(:request_email, "doesn't look like a valid email address")
            end
        end
    end

    # Can an FOI (etc.) request be made to this body, and if not why not?
    def is_requestable?
        if self.request_email.nil?
            return false
        end
        return !self.request_email.empty? && self.request_email != 'blank' && self.request_email != 'not_apply'
    end
    def not_requestable_reason
        if self.request_email.empty? or self.request_email == 'blank'
            return 'bad_contact'
        elsif self.request_email == 'not_apply'
            return 'not_apply'
        else
            raise "requestable_failure_reason called with type that has no reason"
        end
    end

    acts_as_versioned
    self.non_versioned_columns << 'created_at' << 'updated_at' << 'first_letter'
    class Version
        attr_accessor :created_at

        def last_edit_comment_for_html_display
            text = self.last_edit_comment.strip
            text = CGI.escapeHTML(text)
            text = MySociety::Format.make_clickable(text)
            text = text.gsub(/\n/, '<br>')
            return text
        end
    end

    acts_as_xapian :texts => [ :name, :short_name, :notes ],
        :values => [ 
             [ :created_at_numeric, 1, "created_at", :number ] # for sorting
        ],
        :terms => [ [ :variety, 'V', "variety" ] ]
    def created_at_numeric
        # format it here as no datetime support in Xapian's value ranges
        return self.created_at.strftime("%Y%m%d%H%M%S") 
    end
    def variety
        "authority"
    end

    # When name or short name is changed, also change the url name
    def short_name=(short_name)
        write_attribute(:short_name, short_name)
        self.update_url_name
    end
    def name=(name)
        write_attribute(:name, name)
        self.update_url_name
    end
    def update_url_name
        url_name = MySociety::Format.simplify_url_part(self.short_or_long_name)
        write_attribute(:url_name, url_name)
    end
    # Return the short name if present, or else long name
    def short_or_long_name
        if self.short_name.nil? # can happen during construction
            self.name
        else
            self.short_name.empty? ? self.name : self.short_name
        end
    end

    # Given an input string of tags, sets all tags to that string
    def tag_string=(tag_string)
        tags = tag_string.split(/\s+/).uniq

        ActiveRecord::Base.transaction do
            for public_body_tag in self.public_body_tags
                public_body_tag.destroy
            end
            for tag in tags
                public_body_tag = PublicBodyTag.new(:name => tag)
                self.public_body_tags << public_body_tag
                public_body_tag.public_body = self
            end
        end
    end
    def tag_string
        return self.public_body_tags.map { |t| t.name }.join(' ')
    end
    def has_tag?(tag)
        for public_body_tag in self.public_body_tags
            if public_body_tag.name == tag
                return true
            end
        end 
        return false
    end

    # Find all public bodies with a particular tag
    def self.find_by_tag(tag) 
        return PublicBodyTag.find(:all, :conditions => ['name = ?', tag] ).map { |t| t.public_body }.sort { |a,b| a.name <=> b.name }
    end

    # Use tags to describe what type of thing this is
    def type_of_authority(html = false)
        types = []
        first = true
        for tag in self.public_body_tags
            if PublicBody.categories_by_tag.include?(tag.name)
                desc = PublicBody.category_singular_by_tag[tag.name] 
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
            return ret
        else
            return "A public authority"
        end
    end

    # Guess home page from the request email, or use explicit override, or nil
    # if not known.
    def calculated_home_page
        # manual override for ones we calculate wrongly
        if self.home_page != ''
            return self.home_page
        end

        # extract the domain name from the FOI request email
        url = self.request_email_domain
        if url.nil?
            return nil
        end

        # add standard URL prefix
        return "http://www." + url
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

    # The "internal admin" is a special body for internal use.
    def PublicBody.internal_admin_body
        pb = PublicBody.find_by_url_name("internal_admin_authority")
        if pb.nil?
            pb = PublicBody.new(
                :name => 'Internal admin authority',
                :short_name => "",
                :request_email => MySociety::Config.get("CONTACT_EMAIL", 'contact@localhost'),
                :home_page => "",
                :notes => "",
                :last_edit_editor => "internal_admin",
                :last_edit_comment => "Made by PublicBody.internal_admin_body"
            )
            pb.save!
        end

        return pb
    end


    class ImportCSVDryRun < StandardError
    end

    # Import from CSV. Just tests things and returns messages if dry_run is true.
    # Returns an array of [array of errors, array of notes]. If there are errors,
    # always rolls back (as with dry_run).
    def self.import_csv(csv, tag, dry_run, editor)
        errors = []
        notes = []

        begin
            ActiveRecord::Base.transaction do
                existing_bodies = PublicBody.find_by_tag(tag)

                bodies_by_name = {}
                set_of_existing = Set.new()
                for existing_body in existing_bodies
                    bodies_by_name[existing_body.name] = existing_body
                    set_of_existing.add(existing_body.name)
                end

                set_of_importing = Set.new()
                line = 0

                CSV::Reader.parse(csv) do |row|
                    line = line + 1

                    name = row[1]
                    email = row[2]
                    next if name.nil?
                    if email.nil?
                        email = '' # unknown/bad contact is empty string
                    end

                    name.strip!
                    email.strip!

                    if email != "" && !MySociety::Validate.is_valid_email(email)
                        errors.push "error: line " + line.to_s + ": invalid email " + email + " for authority '" + name + "'"
                        next
                    end

                    if bodies_by_name[name]
                        # Already have the public body, just update email
                        public_body = bodies_by_name[name]
                        if public_body.request_email != email
                            notes.push "line " + line.to_s + ": updating email for '" + name + "' from " + public_body.request_email + " to " + email
                            public_body.request_email = email
                            public_body.last_edit_editor = editor
                            public_body.last_edit_comment = 'Updated from spreadsheet'
                            public_body.save!
                        end
                    else
                        # New public body
                        notes.push "line " + line.to_s + ": new authority '" + name + "' with email " + email
                        public_body = PublicBody.new(:name => name, :request_email => email, :short_name => "", :home_page => "", :notes => "", :last_edit_editor => editor, :last_edit_comment => 'Created from spreadsheet')
                        public_body.tag_string = tag
                        public_body.save!
                    end

                    set_of_importing.add(name)
                end

                # Give an error listing ones that are to be deleted 
                deleted_ones = set_of_existing - set_of_importing
                if deleted_ones.size > 0
                    notes.push "notes: Some " + tag + " bodies are in database, but not in CSV file:\n    " + Array(deleted_ones).join("\n    ") + "\nYou may want to delete them manually.\n"
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


end


