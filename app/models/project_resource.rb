##
# A model to represent a project resource. These will be either info requests or
# info request batches.
#
class ProjectResource < ApplicationRecord
  belongs_to :project
  belongs_to :resource, polymorphic: true

  validates :project, :resource, presence: true
end
