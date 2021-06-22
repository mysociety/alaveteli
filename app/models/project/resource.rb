# == Schema Information
# Schema version: 20210114161442
#
# Table name: project_resources
#
#  id            :bigint           not null, primary key
#  project_id    :bigint
#  resource_type :string
#  resource_id   :bigint
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

##
# A model to represent a project resource. These will be either info requests or
# info request batches.
#
class Project::Resource < ApplicationRecord
  belongs_to :project
  belongs_to :resource, polymorphic: true

  validates :project, :resource, presence: true
end
