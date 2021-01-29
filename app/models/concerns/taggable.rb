##
# Module concern with methods to help find records with tags
#
module Taggable
  extend ActiveSupport::Concern

  included do
    has_tag_string

    def self.with_tag(tag)
      where("EXISTS(#{tag_search_sql(tag)})")
    end

    def self.without_tag(tag)
      where.not("EXISTS(#{tag_search_sql(tag)})")
    end

    def self.tag_search_sql(tag)
      name, value = HasTagString::HasTagStringTag.split_tag_into_name_value(tag)
      scope = HasTagString::HasTagStringTag.
        select(1).
        where("has_tag_string_tags.model_id = #{quoted_table_name}." \
              "#{quoted_primary_key}").
        where("has_tag_string_tags.model = '#{self}'").
        where(name: name)
      scope = scope.where(value: value) if value
      scope.to_sql
    end
    private_class_method :tag_search_sql

    def self.tags
      HasTagString::HasTagStringTag.where(model_id: all, model: to_s).
        map(&:name_and_value)
    end
  end
end
