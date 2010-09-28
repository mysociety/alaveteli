# lib/has_tag_string.rb:
# Lets a model have tags, represented as space separate strings in a public #
# interface, but stored in the database as keys. Each tag can have a value
# followed by a colon - e.g. url:http://www.flourish.org
#
# Copyright (c) 2010 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/

module HasTagString
    module InstanceMethods
        # Given an input string of tags, sets all tags to that string.
        # XXX This immediately saves the new tags.
        def tag_string=(tag_string)
            tag_string = tag_string.strip
            # split tags apart
            tags = tag_string.split(/\s+/).uniq

            ActiveRecord::Base.transaction do
                for public_body_tag in self.public_body_tags
                    public_body_tag.destroy
                end
                self.public_body_tags = []
                for tag in tags
                    # see if is a machine tags (i.e. a tag which has a value)
                    name, value = PublicBodyTag.split_tag_into_name_value(tag)

                    public_body_tag = PublicBodyTag.new(:name => name, :value => value)
                    self.public_body_tags << public_body_tag
                    public_body_tag.public_body = self
                end
            end
        end
        def tag_string
            return self.public_body_tags.map { |t| t.name_and_value }.join(' ')
        end
        def has_tag?(tag)
            for public_body_tag in self.public_body_tags
                if public_body_tag.name == tag
                    return true
                end
            end 
            return false
        end
        class TagNotFound < StandardError
        end
        def get_tag_values(tag)
            found = false
            results = []
            for public_body_tag in self.public_body_tags
                if public_body_tag.name == tag
                    found = true
                    if !public_body_tag.value.nil?
                        results << public_body_tag.value
                    end
                end
            end 
            if !found
                raise TagNotFound
            end
            return results
        end
        def add_tag_if_not_already_present(tag)
            self.tag_string = self.tag_string + " " + tag
        end

    end

    module ClassMethods
        # Find all public bodies with a particular tag
        def find_by_tag(tag) 
            return PublicBodyTag.find(:all, :conditions => ['name = ?', tag] ).map { |t| t.public_body }.sort { |a,b| a.name <=> b.name }
        end
    end

    ######################################################################
    # Main entry point, add has_tag_string to your model.
    module HasMethods
        def has_tag_string()
            include InstanceMethods
            self.class.send :include, ClassMethods
        end
    end

end

ActiveRecord::Base.extend HasTagString::HasMethods

