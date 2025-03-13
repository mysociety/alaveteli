# == Schema Information
# Schema version: 20231127110827
#
# Table name: categories
#
#  id           :bigint           not null, primary key
#  category_tag :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

##
# Represents a category which can have hierarchical relationships with other
# categories and translatable titles/descriptions.
#
class Category < ApplicationRecord
  include Notable

  has_many :parent_relationships,
           class_name: 'CategoryRelationship',
           foreign_key: 'child_id',
           dependent: :destroy,
           validate: false
  has_many :parents,
           through: :parent_relationships,
           source: :parent

  has_many :child_relationships,
           class_name: 'CategoryRelationship',
           foreign_key: 'parent_id',
           dependent: :destroy,
           validate: false
  has_many :children,
           through: :child_relationships,
           source: :child,
           dependent: :destroy

  has_many :tags,
           foreign_key: :name,
           primary_key: :category_tag,
           class_name: 'HasTagString::HasTagStringTag'

  translates :title, :description
  translates :body, touch: true
  include Translatable
  delegate :body, :body=, :body?, to: :translation
  after_save { body.save if body.changed? }

  validates :title, presence: true
  validate :check_tag_assignments, on: :update

  scope :roots, -> { left_joins(:parents).where(parents: { id: nil }) }
  scope :with_parent, ->(parent) do
    joins(:parent_relationships).where(parent_relationships: { parent: parent })
  end

  def tree
    children.includes(:translations, children: [:translations])
  end

  def list
    Category.where(id: list_ids).includes(:translations)
  end

  def root
    Category.roots.find { _1.list_ids.include?(id) }
  end

  protected

  def list_ids
    sql = <<~SQL.squish
      WITH RECURSIVE nested_categories AS (
        SELECT child_id
        FROM category_relationships
        WHERE parent_id = :parent_id

        UNION ALL

        SELECT cr.child_id
        FROM category_relationships cr
        INNER JOIN nested_categories nc ON cr.parent_id = nc.child_id
      )
      SELECT DISTINCT c.id FROM categories c
      INNER JOIN nested_categories nc ON c.id = nc.child_id;
    SQL

    Category.find_by_sql([sql, { parent_id: id }]).map(&:id)
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

  class Translation # :nodoc:
    has_rich_text :body
  end
end
