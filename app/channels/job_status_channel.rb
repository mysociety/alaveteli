class JobStatusChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'job_status_channel'
  end
end
