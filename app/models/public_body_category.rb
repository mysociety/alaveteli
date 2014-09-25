# == Schema Information
#
# Table name: public_body_categories
#
#  id            :integer        not null, primary key
#  title         :text           not null
#  category_tag  :text           not null
#  description   :text           not null
#  display_order :integer
#

require 'forwardable'

class PublicBodyCategory < ActiveRecord::Base
    attr_accessible :locale, :category_tag, :title, :description,
                    :translated_versions, :display_order

    has_many :public_body_category_links, :dependent => :destroy
    has_many :public_body_headings, :through => :public_body_category_links

    translates :title, :description
    validates_uniqueness_of :category_tag, :message => N_('Tag is already taken')
    validates_presence_of :title, :message => N_('Title can\'t be blank')
    validates_presence_of :category_tag, :message => N_('Tag can\'t be blank')
    validates_presence_of :description, :message => N_('Description can\'t be blank')

    def self.load_categories
        I18n.available_locales.each do |locale|
            begin
                load "public_body_categories_#{locale}.rb"
            rescue MissingSourceFile
            end
        end
    end
    private_class_method :load_categories

    def self.get
        load_categories if PublicBodyCategory.count < 1

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

    def self.add_category(category_data, heading, locale)
        tag, title, description = category_data
        category = PublicBodyCategory.find_by_category_tag(tag)
        if category
            I18n.with_locale(locale) do
                category.title = title
                category.description = description
                category.save
            end
        else
            category = PublicBodyCategory.create(:category_tag => tag,
                                                 :title => title,
                                                 :description => description)

            # add the translation if this is not the default locale
            # (occurs when a category is not defined in default locale)
            unless category.translations.map { |t| t.locale }.include?(locale)
                I18n.with_locale(locale) do
                    category.title = title
                    category.description = description
                    category.save
                end
            end
        end
        category.add_to_heading(heading)
    end

    def self.add_heading(name, locale)
        matching_headings = PublicBodyHeading.with_translations.where(:name => name)
        if matching_headings.count > 0
            heading = matching_headings.first
            I18n.with_locale(locale) do
                heading.name = name
                heading.save
            end
        else
            I18n.with_locale(locale) do
                heading = PublicBodyHeading.create(:name => name)
            end
        end
        heading
    end

    # Called from the data files themselves
    def self.add(locale, data_list)
        current_heading = nil
        data_list.each do |list_item|
            if list_item.is_a?(Array)
                # item is list of category data
                add_category(list_item, current_heading, locale)
            else
                # item is heading name
                current_heading = add_heading(list_item, locale)
            end
        end
    end

    def add_to_heading(heading)
        if public_body_headings.include?(heading)
            # we already have this, stop
            return
        end
        heading_link = PublicBodyCategoryLink.create(
            :public_body_category_id => self.id,
            :public_body_heading_id => heading.id
        )
    end


    # Convenience methods for creating/editing translations via forms
    def find_translation_by_locale(locale)
        translations.find_by_locale(locale)
    end


    def translated_versions
        translations
    end

    def translated_versions=(translation_attrs)
        def empty_translation?(attrs)
            attrs_with_values = attrs.select{ |key, value| value != '' and key != 'locale' }
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
            translation_attrs.each do |attrs|
                next if empty_translation?(attrs)
                new_translation = PublicBodyCategory::Translation.new(attrs)
                translations << new_translation
            end
        end
    end
end


