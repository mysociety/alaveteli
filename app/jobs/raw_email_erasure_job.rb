class RawEmailErasureJob < ApplicationJob
  queue_as :default

  def perform(raw_email)
    # Do something later
    sleep 2

    RawEmailChannel.erased(raw_email)
  end
end
