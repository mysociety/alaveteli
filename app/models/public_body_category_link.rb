# == Schema Information
# Schema version: 20210114161442
#
# Table name: public_body_category_links
#
#  public_body_category_id :integer          not null
#  public_body_heading_id  :integer          not null
#  category_display_order  :integer
#  id                      :integer          not null, primary key
#  created_at              :datetime
#  updated_at              :datetime
#

class PublicBodyCategoryLink < ApplicationRecord
  belongs_to :public_body_category,
             inverse_of: :public_body_category_links

  belongs_to :public_body_heading,
             inverse_of: :public_body_category_links

  validates :category_display_order, numericality: {
    only_integer: true, message: 'Display order must be a number'
  }

  before_validation on: :create do
    self.category_display_order ||=
      self.class.next_display_order(public_body_heading)
  end

  scope :for_heading, ->(public_body_heading) do
    where(public_body_heading: public_body_heading).
      order(:category_display_order)
  end

  def self.next_display_order(public_body_heading)
    last_record = for_heading(public_body_heading).last

    if last_record
      last_record.category_display_order + 1
    else
      0
    end
  end

  def self.by_display_order
    headings_table = Arel::Table.new(:public_body_headings)
    links_table = Arel::Table.new(:public_body_category_links)

    PublicBodyCategoryLink.
      distinct.
      select(headings_table[:display_order], links_table[Arel.star]).
      joins(:public_body_heading).
      merge(PublicBodyHeading.by_display_order).
      joins(public_body_category: :public_bodies).
      merge(PublicBody.is_requestable).
      order(:category_display_order).
      preload(
        public_body_heading: :translations,
        public_body_category: :translations
      )
  end
end
