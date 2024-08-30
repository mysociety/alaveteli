# == Schema Information
# Schema version: 20240905062817
#
# Table name: workflow_jobs
#
#  id            :bigint           not null, primary key
#  type          :string
#  resource_type :string
#  resource_id   :bigint
#  status        :integer
#  parent_id     :bigint
#  metadata      :jsonb
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

##
# This class represents a job within a workflow.
#
# Note: This class serves as a base for specific job types in the workflow
# system. Subclasses should implement the perform and content_type methods.
#
class Workflow::Job < ApplicationRecord
  self.table_name = 'workflow_jobs'

  include Workflow::Source
  include Workflow::Transitions

  serialize :metadata, type: Hash, coder: JSON, default: {}

  belongs_to :resource, polymorphic: true
  belongs_to :parent, class_name: 'Workflow::Job', optional: true

  def perform
    raise NotImplementedError
  end

  def content_type
    raise NotImplementedError
  end
end
