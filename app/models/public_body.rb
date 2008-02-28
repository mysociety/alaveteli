# == Schema Information
# Schema version: 39
#
# Table name: public_bodies
#
#  id                :integer         not null, primary key
#  name              :text            not null
#  short_name        :text            not null
#  request_email     :text            not null
#  complaint_email   :text            
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
# $Id: public_body.rb,v 1.26 2008-02-28 15:17:46 francis Exp $

require 'csv'

class PublicBody < ActiveRecord::Base
    validates_presence_of :name
    validates_presence_of :url_name
    validates_presence_of :request_email

    has_many :info_requests
    has_many :public_body_tags

    #acts_as_solr :fields => [:name, :short_name]

    def validate
        unless MySociety::Validate.is_valid_email(self.request_email)
            errors.add(:request_email, "doesn't look like a valid email address")
        end
        if self.complaint_email != ""
            unless MySociety::Validate.is_valid_email(self.complaint_email)
                errors.add(:complaint_email, "doesn't look like a valid email address")
            end
        end
    end

    acts_as_versioned
    self.non_versioned_columns << 'created_at' << 'updated_at'

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
                self.public_body_tags << PublicBodyTag.new(:name => tag)
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

    # Import from CSV 
    def self.import_csv(csv, tag)
        ActiveRecord::Base.transaction do
            existing_bodies = PublicBody.find_by_tag(tag)

            bodies_by_name = {}
            for existing_body in existing_bodies
                bodies_by_name[existing_body.name] = existing_body
            end

            CSV::Reader.parse(csv) do |row|
                name = row[1]
                email = row[2]
                next if name.nil? or email.nil?

                name.strip!
                email.strip!
                print name, " ", email, "\n"

                if bodies_by_name[name]
                    public_body = bodies_by_name[name]
                    if public_body.request_email != email
                        public_body.request_email = email
                        public_body.last_edit_editor = 'import_csv'
                        public_body.last_edit_comment = 'Updated from spreadsheet'
                        public_body.save
                    end
                else
                    public_body = PublicBody.new(:name => name, :request_email => email, :complaint_email => "", :short_name => "", :last_edit_editor => "import_csv", :last_edit_comment => 'Created from spreadsheet')
                    public_body.save! # XXX shouldn't need this save, but without it the PublicBodyTag doesn't validate as no PublicBody id, and there is no harm cause we're in a transaction
                    public_body.tag_string = tag
                    public_body.save!
                end
            end

            # XXX what about if they are deleted?
        end
    end
end


