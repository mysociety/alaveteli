# == Schema Information
# Schema version: 20220210114052
#
# Table name: public_body_headings
#
#  id            :integer          not null, primary key
#  display_order :integer
#  created_at    :datetime
#  updated_at    :datetime
#

class PublicBodyHeading < ApplicationRecord
  has_many :public_body_category_links,
           inverse_of: :public_body_heading,
           dependent: :destroy

  has_many :public_body_categories,
           -> { merge(PublicBodyCategoryLink.order(:category_display_order)) },
           through: :public_body_category_links

  scope :by_display_order, -> { order(:display_order) }

  translates :name

  validates_uniqueness_of :name, message: 'Name is already taken'
  validates_presence_of :name, message: "Name can't be blank"

  validates :display_order, numericality: {
    only_integer: true, message: 'Display order must be a number'
  }

  before_validation on: :create do
    unless display_order
      self.display_order = PublicBodyHeading.next_display_order
    end
  end

  include Translatable

  def add_category(category)
    unless public_body_categories.include?(category)
      public_body_categories << category
    end
  end

  def self.next_display_order
    if (max = maximum(:display_order))
      max + 1
    else
      0
    end
  end
end
