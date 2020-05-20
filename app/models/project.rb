# == Schema Information
# Schema version: 20200520073810
#
# Table name: projects
#
#  id           :integer          not null, primary key
#  title        :string
#  briefing     :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  invite_token :string
#

##
# A model to represent a FOI project which many contributors work on multiple
# info requests.
#
class Project < ApplicationRecord
  has_many :memberships, class_name: 'Project::Membership'
  has_one  :owner_membership,
           -> { where(role: Role.project_owner_role) },
           class_name: 'Project::Membership'
  has_many :contributor_memberships,
           -> { where(role: Role.project_contributor_role) },
           class_name: 'Project::Membership'

  has_many :members, through: :memberships, source: :user
  has_one  :owner, through: :owner_membership, source: :user
  has_many :contributors, through: :contributor_memberships, source: :user

  has_many :resources, class_name: 'Project::Resource'
  has_many :requests,
           through: :resources,
           source: :resource,
           source_type: 'InfoRequest'
  has_many :batches,
           through: :resources,
           source: :resource,
           source_type: 'InfoRequestBatch'

  has_many :info_requests,
           ->(project) { unscope(:where).for_project(project) }

  has_one :key_set, class_name: 'Dataset::KeySet', as: :resource

  has_many :submissions, class_name: 'Project::Submission'

  validates :title, :owner, presence: true

  def info_request?(info_request)
    info_requests.include?(info_request)
  end

  def owner?(user)
    user == owner
  end

  def member?(user)
    members.include?(user)
  end

  def contributor?(user)
    contributors.include?(user)
  end

  def classifiable_requests
    info_requests.where(awaiting_description: true)
  end

  def classified_requests
    info_requests.where(awaiting_description: false)
  end

  def classification_progress
    ((classified_requests.count / info_requests.count.to_f) * 100).floor
  end
end
