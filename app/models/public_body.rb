# == Schema Information
# Schema version: 45
#
# Table name: public_bodies
#
#  id                :integer         not null, primary key
#  name              :text            not null
#  short_name        :text            not null
#  request_email     :text            not null
#  version           :integer         not null
#  last_edit_editor  :string(255)     not null
#  last_edit_comment :text            not null
#  created_at        :datetime        not null
#  updated_at        :datetime        not null
#  url_name          :text            not null
#

# models/public_body.rb:
# A public body, from which information can be requested.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: public_body.rb,v 1.46 2008-03-24 20:17:01 francis Exp $

require 'csv'
require 'set'

class PublicBody < ActiveRecord::Base
    validates_presence_of :name
    validates_presence_of :url_name
    
    has_many :info_requests
    has_many :public_body_tags

    def self.categories_with_description
        [
            [ "department", "Ministerial departments", "a ministerial department" ], 
            [ "local_council", "Local councils", "a local council" ], 
            [ "non_ministerial_department", "Non-ministerial departments", "a non-ministerial department" ], 
            [ "npa", "National park authorities", "a national park authority" ], 
            [ "media", "Media", "a media organisation" ],
            [ "police", "Police forces", "a police force" ], 
            [ "rda", "Regional development agencies", "a regional development agency" ], 
            [ "university", "Universities", "university" ], 
            [ "other", "Other", "other" ]
        ]
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


    def validate
        # Request_email can be blank, meaning we don't have details
        if self.request_email != ""
            unless MySociety::Validate.is_valid_email(self.request_email)
                errors.add(:request_email, "doesn't look like a valid email address")
            end
        end
    end

    acts_as_versioned
    self.non_versioned_columns << 'created_at' << 'updated_at'

    acts_as_solr :fields => [
        {:name => { :boost => 10.0 }}, 
        {:short_name => { :boost => 10.0 }},
        { :created_at => :date }
    ]

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

    # Find all public bodies with a particular tag
    def self.find_by_tag(tag) 
        return PublicBodyTag.find(:all, :conditions => ['name = ?', tag] ).map { |t| t.public_body }
    end

    # Use tags to describe what type of thing this is
    def type_of_authority
        types = []
        for tag in self.public_body_tags
            if PublicBody.categories_by_tag.include?(tag.name)
                types.push(PublicBody.category_singular_by_tag[tag.name])
            end
        end
        if types.size > 0
            types.join(", ")
        else
            return "a public authority"
        end
    end

    # Import from CSV 
    def self.import_csv(csv, tag)
        ActiveRecord::Base.transaction do
            existing_bodies = PublicBody.find_by_tag(tag)

            bodies_by_name = {}
            set_of_existing = Set.new()
            for existing_body in existing_bodies
                bodies_by_name[existing_body.name] = existing_body
                set_of_existing.add(existing_body.name)
            end

            set_of_importing = Set.new()
            CSV::Reader.parse(csv) do |row|
                name = row[1]
                email = row[2]
                next if name.nil? or email.nil?

                name.strip!
                email.strip!

                if not MySociety::Validate.is_valid_email(email)
                    raise "invalid email:", name, " ", email, "\n"
                end

                if bodies_by_name[name]
                    # Already have the public body, just update email
                    public_body = bodies_by_name[name]
                    if public_body.request_email != email
                        public_body.request_email = email
                        public_body.last_edit_editor = 'import_csv'
                        public_body.last_edit_comment = 'Updated from spreadsheet'
                        public_body.save
                    end
                else
                    # New public body
                    public_body = PublicBody.new(:name => name, :request_email => email, :short_name => "", :last_edit_editor => "import_csv", :last_edit_comment => 'Created from spreadsheet')
                    public_body.tag_string = tag
                    public_body.save!

                end

                set_of_importing.add(name)
            end

            # Give an error listing ones that are to be deleted 
            deleted_ones = set_of_existing - set_of_importing
            if deleted_ones.size > 0
                raise "Some " + tag + " bodies are in database, but not in CSV file:\n" + Array(deleted_ones).join(", ")
            end
        end
    end
end


