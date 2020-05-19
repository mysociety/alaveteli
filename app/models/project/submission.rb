# == Schema Information
# Schema version: 20200509082917
#
# Table name: project_submissions
#
#  id            :integer          not null, primary key
#  project_id    :integer
#  user_id       :integer
#  resource_type :string
#  resource_id   :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

##
# A submission to a Project by one of its members. Can either be an Info Request
# status update (Classification) or an extraction of data (Dataset::ValueSet).
#
class Project::Submission < ApplicationRecord
  belongs_to :project
  belongs_to :user
  belongs_to :resource, polymorphic: true

  RESOURCE_TYPES = %w[
    InfoRequestEvent
    Dataset::ValueSet
  ].freeze

  validates :project, :user, :resource, presence: true
  validates :resource_type, inclusion: { in: RESOURCE_TYPES }
  validates_associated :resource
end
