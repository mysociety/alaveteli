# == Schema Information
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
#  parent_id       :bigint
#  current         :boolean          default(TRUE), not null
#

##
# A submission to a Project by one of its members. Can either be an Info Request
# status update (Classification) or an extraction of data (Dataset::ValueSet).
#
class Project::Submission < ApplicationRecord
  belongs_to :project
  belongs_to :user
  belongs_to :info_request
  belongs_to :resource, polymorphic: true, optional: true
  belongs_to :parent, class_name: 'Project::Submission', optional: true

  has_many :versions, class_name: 'Project::Submission',
                      foreign_key: :parent_id,
                      dependent: :destroy

  scope :classification, -> { where(resource_type: 'InfoRequestEvent') }
  scope :extraction, -> { where(resource_type: 'Dataset::ValueSet') }
  scope :current, -> { where(current: true) }
  scope :historical, -> { where(current: false) }

  RESOURCE_TYPES = %w[
    InfoRequestEvent
    Dataset::ValueSet
  ].freeze

  validates :resource_type, inclusion: { in: RESOURCE_TYPES }
  validates_associated :resource

  def original_submission
    parent || self
  end

  def create_new_version(attributes = {})
    new_version = self.class.new(
      project: project,
      info_request: info_request,
      parent: original_submission,
      resource_type: resource_type
    )

    new_version.assign_attributes(attributes)

    if new_version.save
      original_submission.versions.current.update_all(current: false)
      new_version.update!(current: true)
    end

    new_version
  end
end
