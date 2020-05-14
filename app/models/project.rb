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

  has_many :resources, class_name: 'ProjectResource'
  has_many :requests,
           through: :resources,
           source: :resource,
           source_type: 'InfoRequest'
  has_many :batches,
           through: :resources,
           source: :resource,
           source_type: 'InfoRequestBatch'

  has_many :info_requests, lambda { |project|
    unscope(:where).
    joins(
      "LEFT JOIN project_resources r1 ON " \
      "r1.resource_id = info_requests.id AND " \
      "r1.resource_type = 'InfoRequest'"
    ).
    joins(
      "LEFT JOIN project_resources r2 ON " \
      "r2.resource_id = info_requests.info_request_batch_id AND " \
      "r2.resource_type = 'InfoRequestBatch'"
    ).
    where("r1.project_id = :id OR r2.project_id = :id", id: project.id)
  }

  has_one :key_set, class_name: 'Dataset::KeySet', as: :resource

  validates :title, :owner, presence: true

  def info_request?(info_request)
    info_requests.include?(info_request)
  end

  def member?(user)
    members.include?(user)
  end

  def classifiable_requests
    info_requests.where(awaiting_description: true)
  end
end
