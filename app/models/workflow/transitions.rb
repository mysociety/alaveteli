##
# This module that provides functionality for managing workflow transitions
# and statuses.
#
module Workflow::Transitions
  extend ActiveSupport::Concern

  included do
    enum :status, %i[pending queued processing failed completed],
                  default: :pending
  end

  def run
    return unless valid?
    return if completed?

    process!
  end

  def perform!
    self.source = perform
    complete!
  rescue StandardError => ex
    fail!(ex)
  end

  def reset!
    destroy!
  end

  def process!
    metadata.delete(:error)
    metadata.delete(:backtrace)

    processing!

    WorkflowJob.perform_later(self)
  end

  private

  def fail!(exception)
    metadata[:error] = exception.message
    metadata[:backtrace] = exception.backtrace

    failed!
  end

  def complete!
    metadata.delete(:error)
    metadata.delete(:backtrace)

    completed!

    # perform next queued job in the sequence
    next_insight = Workflow::Job.queued.find_by(parent: self)
    next_insight.process! if next_insight
  end
end
