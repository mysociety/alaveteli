class ApplicationJob < ActiveJob::Base # :nodoc:
  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer
  # available
  discard_on ActiveJob::DeserializationError

  def self.perform_later(*args)
    return super unless AlaveteliConfiguration.background_jobs == 'inline'
    perform_now(*args)
  end
end
