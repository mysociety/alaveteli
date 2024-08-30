##
# The Workflow class represents a sequence of jobs to be executed on a resource.
#
# Usage:
#   workflow = Workflow.example(resource)
#   workflow.run
#
# Class Methods:
#   example(resource) - Creates a new example Workflow instance
#
class Workflow
  def self.example(resource)
    Workflow.new(
      resource: resource,
      jobs: [
        Workflow::Job,
        Workflow::Job,
        Workflow::Job
      ]
    )
  end

  def initialize(resource:, jobs:)
    @resource = resource
    @klasses = jobs
  end

  def run
    last_job = jobs.last
    return if last_job.completed?

    run_job(last_job.class)
  end

  def run_job(key)
    initial_job, jobs_to_queue, jobs_to_reset = plan_workflow(key)

    jobs_to_queue.each(&:queued!)
    initial_job.pending!
    initial_job.run
    jobs_to_reset.each(&:reset!)
  end

  def jobs
    @jobs ||= @klasses.inject([]) do |jobs, klass|
      jobs << klass.find_or_initialize_by(
        resource: @resource, parent: jobs.last
      )
    end
  end

  private

  def plan_workflow(key)
    queue = []
    reset = []

    jobs.each do |s|
      # once the current job is queued the rest of the workflow is reset
      if queue.all? { !_1.is_a?(key) }
        # skip completed jobs at the beginning of the workflow, but ensure the
        # current job is queued
        next if queue.empty? && s.completed? && !s.is_a?(key)

        queue << s
      else
        reset << s
      end
    end

    [queue.shift, queue, reset]
  end
end
