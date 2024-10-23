class RawEmailChannel < ApplicationCable::Channel
  def self.erased(raw_email)
    broadcast_to raw_email, data: { event: :erased }
  end

  def subscribed
    raw_email = RawEmail.find(params[:id])
    stream_for raw_email
  end
end
