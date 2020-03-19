##
# A model to represent a FOI project which many contributors work on multiple
# info requests.
#
class Project < ApplicationRecord
  has_many :memberships, class_name: 'ProjectMembership'
  has_one  :owner_membership,
           -> { where(role: Role.project_owner_role) },
           class_name: 'ProjectMembership'
  has_many :contributor_memberships,
           -> { where(role: Role.project_contributor_role) },
           class_name: 'ProjectMembership'

  has_many :members, through: :memberships, source: :user
  has_one  :owner, through: :owner_membership, source: :user
  has_many :contributors, through: :contributor_memberships, source: :user

  validates :title, :owner, presence: true
end
