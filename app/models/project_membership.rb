##
# A model to represent user membership to a project. Able to assign different
# roles for owners and contributors.
#
class ProjectMembership < ApplicationRecord
  belongs_to :project
  belongs_to :user
  belongs_to :role

  validates :project, :user, :role, presence: true
end
