# == Schema Information
#
# Table name: category_relationships
#
#  id         :bigint           not null, primary key
#  parent_id  :integer          not null
#  child_id   :integer          not null
#  position   :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

##
# Manages hierarchical relationships between categories, including parent-child
# links and custom ordering.
#
class CategoryRelationship < ApplicationRecord
  default_scope { order(position: :asc) }

  belongs_to :parent, class_name: 'Category', validate: true
  belongs_to :child, class_name: 'Category', validate: true

  before_validation :set_next_position, on: :create, unless: -> { position }

  validates :position, presence: true, numericality: { only_integer: true }

  private

  def set_next_position
    max_position = CategoryRelationship.
      where(parent_id: parent_id).
      maximum(:position) || 0

    self.position = max_position.next
  end
end
