# -*- encoding : utf-8 -*-
# lib/has_tag_string.rb:
# Lets a model have tags, represented as space separate strings in a public
# interface, but stored in the database as keys. Each tag can have a value
# followed by a colon - e.g. url:http://www.flourish.org
#
# Copyright (c) 2010 UK Citizens Online Democracy. All rights reserved.
# Email: hello@mysociety.org; WWW: http://www.mysociety.org/

module HasTagString
  # Represents one tag of one model.
  # The migration to make this is currently only in WDTK code.
  class HasTagStringTag < ActiveRecord::Base
    # TODO: strip_attributes!

    validates_presence_of :name

    # Return instance of the model that this tag tags
    def tagged_model
      return self.model.constantize.find(self.model_id)
    end

    # For display purposes, returns the name and value as a:b, or
    # if there is no value just the name a
    def name_and_value
      ret = self.name
      if !self.value.nil?
        ret += ":" + self.value
      end
      return ret
    end

    # Parses a text version of one single tag, such as "a:b" and returns
    # the name and value, with nil for value if there isn't one.
    def self.split_tag_into_name_value(tag)
      sections = tag.split(/:/)
      name = sections[0]
      if sections[1]
        value = sections[1,sections.size].join(":")
      else
        value = nil
      end
      return name, value
    end
  end

  # Methods which are added to the model instances being tagged
  module InstanceMethods
    # Given an input string of tags, sets all tags to that string.
    # TODO: This immediately saves the new tags.
    def tag_string=(tag_string)
      if tag_string.nil?
        tag_string = ""
      end

      tag_string = tag_string.strip
      # split tags apart
      tags = tag_string.split(/\s+/).uniq

      ActiveRecord::Base.transaction do
        for tag in self.tags
          tag.destroy
        end
        self.tags = []
        for tag in tags
          # see if is a machine tags (i.e. a tag which has a value)
          name, value = HasTagStringTag.split_tag_into_name_value(tag)

          tag = HasTagStringTag.new(
            :model => self.class.base_class.to_s,
            :model_id => self.id,
            :name => name, :value => value
          )
          self.tags << tag
        end
      end
    end

    # Returns the tags the model has, as a space separated string
    def tag_string
      return self.tags.map { |t| t.name_and_value }.join(' ')
    end

    # Returns the tags the model has, as an array of pairs of key/value
    # (this can't be a dictionary as you can have multiple instances of a
    # key with different values)
    def tag_array
      return self.tags.map { |t| [t.name, t.value] }
    end

    # Returns a list of all the strings someone might want to search for.
    # So that is the key by itself, or the key and value.
    # e.g. if a request was tagged openlylocal_id:12345, they might
    # want to search for "openlylocal_id" or for "openlylocal_id:12345" to find it.
    def tag_array_for_search
      ret = {}
      for tag in self.tags
        ret[tag.name] = 1
        ret[tag.name_and_value] = 1
      end

      return ret.keys.sort
    end

    # Test to see if class is tagged with the given tag
    def has_tag?(tag_as_string)
      for tag in self.tags
        if tag.name == tag_as_string
          return true
        end
      end
      return false
    end

    class TagNotFound < StandardError
    end

    # If the tag is a machine tag, returns array of its values
    def get_tag_values(tag_as_string)
      found = false
      results = []
      for tag in self.tags
        if tag.name == tag_as_string
          found = true
          if !tag.value.nil?
            results << tag.value
          end
        end
      end
      if !found
        raise TagNotFound
      end
      return results
    end

    # Adds a new tag to the model, if it isn't already there
    def add_tag_if_not_already_present(tag_as_string)
      self.tag_string = self.tag_string + " " + tag_as_string
    end
  end

  # Methods which are added to the model class being tagged
  module ClassMethods
    # Find all public bodies with a particular tag
    def find_by_tag(tag_as_string)
      return HasTagStringTag.find(:all, :conditions =>
                                  ['name = ? and model = ?', tag_as_string, self.to_s ]
                                  ).map { |t| t.tagged_model }.sort { |a,b| a.name <=> b.name }.uniq
    end
  end

  ######################################################################
  # Main entry point, add has_tag_string to your model.
  module HasMethods
    def has_tag_string
      has_many :tags, :conditions => "model = '" + self.to_s + "'", :foreign_key => "model_id", :class_name => 'HasTagString::HasTagStringTag'

      include InstanceMethods
      self.class.send :include, ClassMethods
    end
  end

end

ActiveRecord::Base.extend HasTagString::HasMethods
