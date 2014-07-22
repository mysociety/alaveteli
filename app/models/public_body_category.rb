# == Schema Information
#
# Table name: public_body_categories
#
#  id            :integer        not null, primary key
#  title         :text           not null
#  category_tag  :text           not null
#  description   :text           not null
#

require 'forwardable'

class PublicBodyCategory < ActiveRecord::Base
    attr_accessible :locale, :category_tag, :title, :description, :translated_versions

    has_and_belongs_to_many :public_body_headings

    translates :title, :description
    validates_uniqueness_of :category_tag, :message => N_('Tag is already taken')
    validates_presence_of :title, :message => N_('Title can\'t be blank')
    validates_presence_of :category_tag, :message => N_('Tag can\'t be blank')
    validates_presence_of :description, :message => N_('Description can\'t be blank')

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
                      FROM public_body_categories_public_body_headings
                  ) |
        PublicBodyCategory.find_by_sql(sql)
    end

    # Called from the data files themselves
    def self.add(locale, categories)
        @heading = nil
        categories.each do |category|
            if category.is_a?(Array)
                #categories
                pb_category = PublicBodyCategory.find_by_category_tag(category[0])
                unless pb_category
                    pb_category = PublicBodyCategory.create(
                        {
                            :category_tag => category[0],
                            :title => category[1],
                            :description => category[2]
                        }
                    )
                    # add the translation if this is not the default locale
                    # (occurs when a category is not defined in default locale)
                    unless pb_category.translations.map { |t| t.locale }.include?(locale)
                        I18n.with_locale(locale) do
                            pb_category.title = category[1]
                            pb_category.description = category[2]
                            pb_category.save
                        end
                    end
                    pb_category.public_body_headings << @heading
                else
                    I18n.with_locale(locale) do
                        pb_category.title = category[1]
                        pb_category.description = category[2]
                        pb_category.save
                    end
                end
            else
                #headings
                matching_headings = PublicBodyHeading.with_translations.where(:name => category)
                if matching_headings.count > 0
                    @heading = matching_headings.first
                    I18n.with_locale(locale) do
                        @heading.name = category
                        @heading.save
                    end
                else
                    I18n.with_locale(locale) do
                        @heading = PublicBodyHeading.create(:name => category)
                    end
                end
            end
        end
    end

    # Convenience methods for creating/editing translations via forms
    def find_translation_by_locale(locale)
        self.translations.find_by_locale(locale)
    end

    def skip?(attrs)
        valueless = attrs.inject({}) { |h, (k, v)| h[k] = v if v != '' and k != 'locale'; h } # because we want to fall back to alternative translations where there are empty values
        return valueless.length == 0
     end

    def translated_versions
        translations
    end

    def translated_versions=(translation_attrs)
        if translation_attrs.respond_to? :each_value    # Hash => updating
            translation_attrs.each_value do |attrs|
                next if skip?(attrs)
                t = translation_for(attrs[:locale]) || PublicBodyCategory::Translation.new
                t.attributes = attrs
                t.save!
            end
        else                                            # Array => creating
            translation_attrs.each do |attrs|
                next if skip?(attrs)
                new_translation = PublicBodyCategory::Translation.new(attrs)
                translations << new_translation
            end
        end
    end

    private
    def self.load_categories()
        I18n.available_locales.each do |locale|
            begin
                load "public_body_categories_#{locale}.rb"
            rescue MissingSourceFile
            end
        end
    end
end

# replicate original file-based PublicBodyCategories functionality
class CategoryCollection
    include Enumerable
    extend Forwardable
    def_delegators :@categories, :each, :<<

    def initialize
        @categories = []
    end

    def with_headings
        @categories
    end

    def with_description
        @categories.select() { |a| a.instance_of?(Array) }
    end

    def tags
        tags = with_description.map() { |a| a[0] }
    end

    def by_tag
        Hash[*with_description.map() { |a| a[0..1] }.flatten]
    end

    def singular_by_tag
        Hash[*with_description.map() { |a| [a[0],a[2]] }.flatten]
    end

    def by_heading
        output = {}
        heading = nil
        @categories.each do |row|
            if row.is_a?(Array)
                output[heading] << row[0]
            else
                heading = row
                output[heading] = []
            end
        end
        output
    end

    def headings
        output = []
        @categories.each do |row|
            unless row.is_a?(Array)
                output << row
            end
        end
        output
    end
end
