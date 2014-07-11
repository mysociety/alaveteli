# == Schema Information
#
# Table name: public_body_categories
#
#  id            :integer        not null, primary key
#  locale        :string
#  title         :text           not null
#  category_tag  :text           not null
#  description   :text           not null
#

require 'forwardable'

class PublicBodyCategory < ActiveRecord::Base
    attr_accessible :locale, :category_tag, :title, :description

    has_and_belongs_to_many :public_body_headings

    def self.get
        locale = I18n.locale.to_s || default_locale.to_s || ""
        headings = PublicBodyHeading.find_all_by_locale(locale)
        categories = CategoryCollection.new
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
        categories
    end

    # Called from the data files themselves
    def self.add(locale, categories)
        heading = nil
        categories.each do |category|
            if category.is_a?(Array)
                #categories
                unless PublicBodyCategory.find_by_locale_and_category_tag(locale, category[0])
                    pb_category = PublicBodyCategory.new(
                        {
                            :locale => locale,
                            :category_tag => category[0],
                            :title => category[1],
                            :description => category[2]
                        }
                    )
                    pb_category.public_body_headings << heading
                    pb_category.save
                end
            else
                #headings
                heading = PublicBodyHeading.find_or_create_by_locale_and_name(locale, category)
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
