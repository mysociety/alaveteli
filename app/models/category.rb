# == Schema Information
# Schema version: 20231127110827
#
# Table name: categories
#
#  id           :bigint           not null, primary key
#  category_tag :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  title        :string
#  description  :string
#

##
# Represents a category which can have hierarchical relationships with other
# categories and translatable titles/descriptions.
#
class Category < ApplicationRecord
  has_many :parent_relationships,
           class_name: 'CategoryRelationship',
           foreign_key: 'child_id',
           dependent: :destroy
  has_many :parents,
           through: :parent_relationships,
           source: :parent

  has_many :child_relationships,
           class_name: 'CategoryRelationship',
           foreign_key: 'parent_id',
           dependent: :destroy
  has_many :children,
           through: :child_relationships,
           source: :child,
           dependent: :destroy

  has_many :tags,
           foreign_key: :name,
           primary_key: :category_tag,
           class_name: 'HasTagString::HasTagStringTag'

  translates :title, :description
  include Translatable

  validates :title, presence: true
  validate :check_tag_assignments, on: :update

  scope :roots, -> { left_joins(:parents).where(parents: { id: nil }) }
  scope :with_parent, ->(parent) do
    joins(:parent_relationships).where(parent_relationships: { parent: parent })
  end

  def self.public_body_root
    Category.roots.find_or_create_by(title: 'PublicBody')
  end

  def tree
    children.includes(:translations, children: [:translations])
  end

  private

  def check_tag_assignments
    return unless category_tag_changed?
    return if HasTagString::HasTagStringTag.where(name: category_tag_was).none?

    errors.add(
      :category_tag,
      message: "can't be changed as there are associated objects present"
    )
  end
end
