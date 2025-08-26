# == Schema Information
# Schema version: 20210114161442
#
# Table name: project_submissions
#
#  id              :bigint           not null, primary key
#  project_id      :bigint
#  user_id         :bigint
#  resource_type   :string
#  resource_id     :bigint
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  info_request_id :bigint
#

##
# A submission to a Project by one of its members. Can either be an Info Request
# status update (Classification) or an extraction of data (Dataset::ValueSet).
#
class Project::Submission < ApplicationRecord
  belongs_to :project
  belongs_to :user
  belongs_to :info_request
  belongs_to :resource, polymorphic: true

  scope :classification, -> { where(resource_type: 'InfoRequestEvent') }
  scope :extraction, -> { where(resource_type: 'Dataset::ValueSet') }

  RESOURCE_TYPES = %w[
    InfoRequestEvent
    Dataset::ValueSet
  ].freeze

  validates :project, :user, :info_request, :resource, presence: true
  validates :resource_type, inclusion: { in: RESOURCE_TYPES }
  validates_associated :resource
end
