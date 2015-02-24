# == Schema Information
#
# Table name: public_body_categories
#
#  id           :integer          not null, primary key
#  category_tag :text             not null
#

require 'forwardable'

class PublicBodyCategory < ActiveRecord::Base
    attr_accessible :locale, :category_tag, :title, :description,
                    :translated_versions, :translations_attributes,
                    :display_order

    has_many :public_body_category_links, :dependent => :destroy
    has_many :public_body_headings, :through => :public_body_category_links

    translates :title, :description
    accepts_nested_attributes_for :translations

    validates_uniqueness_of :category_tag, :message => 'Tag is already taken'
    validates_presence_of :title, :message => "Title can't be blank"
    validates_presence_of :category_tag, :message => "Tag can't be blank"
    validates_presence_of :description, :message => "Description can't be blank"

    def self.get
        locale = I18n.locale.to_s || default_locale.to_s || ""
        categories = CategoryCollection.new
        I18n.with_locale(locale) do
            headings = PublicBodyHeading.all
            headings.each do |heading|
                categories << heading.name
                heading.public_body_categories.each do |category|
                    categories << [
                        category.category_tag,
                        category.title,
                        category.description
                    ]
                end
            end
        end
        categories
    end

    def self.without_headings
        sql = %Q| SELECT * FROM public_body_categories pbc
                  WHERE pbc.id NOT IN (
                      SELECT public_body_category_id AS id
                      FROM public_body_category_links
                  ) |
        PublicBodyCategory.find_by_sql(sql)
    end

    # Called from the old-style public_body_categories_[locale].rb data files
    def self.add(locale, data_list)
        CategoryAndHeadingMigrator.add_categories_and_headings_from_list(locale, data_list)
    end

    # Convenience methods for creating/editing translations via forms
    def find_translation_by_locale(locale)
        translations.find_by_locale(locale)
    end

    def translated_versions
        translations
    end

    def translations_attributes=(translation_attrs)
        def empty_translation?(attrs)
            attrs_with_values = attrs.select{ |key, value| value != '' and key.to_s != 'locale' }
            attrs_with_values.empty?
        end
        if translation_attrs.respond_to? :each_value    # Hash => updating
            translation_attrs.each_value do |attrs|
                next if empty_translation?(attrs)
                t = translation_for(attrs[:locale]) || PublicBodyCategory::Translation.new
                t.attributes = attrs
                t.save!
            end
        else                                            # Array => creating
            warn "[DEPRECATION] PublicBodyCategory#translations_attributes= " \
                 "will no longer accept an Array as of release 0.22. " \
                 "Use Hash arguments instead. See " \
                 "spec/models/public_body_category_spec.rb and " \
                 "app/views/admin_public_body_categories/_form.html.erb for more " \
                 "details."
            translation_attrs.each do |attrs|
                next if empty_translation?(attrs)
                new_translation = PublicBodyCategory::Translation.new(attrs)
                translations << new_translation
            end
        end
    end

    def translated_versions=(translation_attrs)
        warn "[DEPRECATION] PublicBodyCategory#translated_versions= will be replaced " \
             "by PublicBodyCategory#translations_attributes= as of release 0.22"
        self.translations_attributes = translation_attrs
    end
end


