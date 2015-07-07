# -*- encoding : utf-8 -*-
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

    validates_uniqueness_of :category_tag, :message => 'Tag is already taken'
    validates_presence_of :title, :message => "Title can't be blank"
    validates_presence_of :category_tag, :message => "Tag can't be blank"
    validates_presence_of :description, :message => "Description can't be blank"

    include Translatable

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
end

PublicBodyCategory::Translation.class_eval do
  with_options :if => lambda { |t| !t.default_locale? && t.required_attribute_submitted? } do |required|
    required.validates :title, :presence => { :message => "Title can't be blank" }
    required.validates :description, :presence => { :message => "Description can't be blank" }
  end

  def default_locale?
      locale == I18n.default_locale
  end

  def required_attribute_submitted?
    PublicBodyCategory.required_translated_attributes.compact.any? do |attribute|
      !read_attribute(attribute).blank?
    end
  end

end
