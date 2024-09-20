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
# This class represents a job in the workflow system that creates chunks for a resource.
#
class Workflow::Jobs::CreateChunks < Workflow::Job
  after_destroy :destroy_chunks

  def perform
    resource.chunks.create!(text: source).to_gid
  end

  def content_type
    'application/json'
  end

  private

  def destroy_chunks
    resource.chunks.destroy_all
  end
end
