class LongRunningJob < ApplicationJob
  queue_as :default

  def perform(_user_id)
    progress = 0

    while progress < 99
      sleep(rand(0.5..2.0))
      progress += rand(5..15)
      progress = [progress, 99].min

      ActionCable.server.broadcast(
        'job_status_channel',
        {
          status: 'Processing...',
          progress: progress
        }
      )
    end

    ActionCable.server.broadcast(
      'job_status_channel',
      {
        status: 'Completed',
        progress: 100,
        result: "Task completed at #{Time.current}"
      }
    )
  end
end
