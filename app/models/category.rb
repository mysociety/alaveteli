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
end
