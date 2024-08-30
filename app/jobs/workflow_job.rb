##
# WorkflowJob is a background job class that processes workflows.
# It inherits from ApplicationJob and is enqueued in the :workflow queue.
#
# This job takes a workflow object as an argument and calls its perform! method.
#
# Usage:
#   WorkflowJob.perform_later(workflow)
#
# @param workflow [Workflow] The workflow object to be processed
#
class WorkflowJob < ApplicationJob
  queue_as :workflows

  def perform(workflow)
    workflow.perform!
  end
end
