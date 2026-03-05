class ApplicationJob < ActiveJob::Base # :nodoc:
  # Site-wide access to configuration settings
  include ConfigHelper

  # Automatically retry jobs that encountered a deadlock
  retry_on ActiveRecord::Deadlocked

  # Automatically retry jobs 5 times then send exception notification
  retry_on StandardError, wait: :polynomially_longer, attempts: 5 do |job, err|
    next unless job.send_exception_notifications?

    ExceptionNotifier.notify_exception(
      err, data: {
        job: job.class.to_s, job_id: job.job_id, job_arguments: job.arguments
      }
    )
  end

  # Most jobs are safe to ignore if the underlying records are no longer
  # available
  discard_on ActiveJob::DeserializationError
end
