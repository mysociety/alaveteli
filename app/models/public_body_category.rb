# == Schema Information
# Schema version: 20220210114052
#
# Table name: public_body_categories
#
#  id           :integer          not null, primary key
#  category_tag :text             not null
#  created_at   :datetime
#  updated_at   :datetime
#  title        :text
#  description  :text
#

class PublicBodyCategory < ApplicationRecord
  has_many :public_body_category_links,
           :inverse_of => :public_body_category,
           :dependent => :destroy
  has_many :public_body_headings,
           :through => :public_body_category_links

  translates :title, :description

  validates_uniqueness_of :category_tag, :message => 'Tag is already taken'
  validates_presence_of :title, :message => "Title can't be blank"
  validates_presence_of :category_tag, :message => "Tag can't be blank"
  validates_presence_of :description, :message => "Description can't be blank"

  include Translatable

  def self.get
    locale = AlaveteliLocalization.locale || default_locale || ""
    categories = CategoryCollection.new
    AlaveteliLocalization.with_locale(locale) do
      headings = PublicBodyHeading.by_display_order
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
    AlaveteliLocalization.default_locale?(locale)
  end

  def required_attribute_submitted?
    PublicBodyCategory.translated_attribute_names.compact.any? do |attribute|
      !read_attribute(attribute).blank?
    end
  end

end
