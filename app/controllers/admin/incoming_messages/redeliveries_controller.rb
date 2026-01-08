# Allow admins to redeliver an IncomingMessage to a different InfoRequest
class Admin::IncomingMessages::RedeliveriesController < AdminController
  class NotRedeliverableError < StandardError; end

  before_action :set_incoming_message
  before_action :set_info_request, :check_info_request
  before_action :check_redeliverable

  def create
    message_ids = params[:url_title].split(',').map(&:strip)
    previous_request = @incoming_message.info_request
    destination_request = nil

    if message_ids.empty?
      msg = 'You must supply at least one request to redeliver the message to.'
      return redirect_to admin_request_url(previous_request), error: msg
    end

    ActiveRecord::Base.transaction do
      message_ids.each do |m|
        destination_request =
          if m.match(/^[0-9]+$/)
            InfoRequest.find_by_id(m.to_i)
          else
            InfoRequest.find_by_url_title!(m)
          end

        if destination_request.nil?
          return redirect_to admin_request_url(previous_request),
                 error: "Failed to find destination request '#{m}'"
        end

        destination_request.
          receive_redelivery(@incoming_message, editor: admin_current_user)

        flash[:notice] =
          'Message has been moved to request(s). Showing the last one:'
      end

      # expire cached files
      previous_request.expire
      @incoming_message.destroy
    end

    redirect_to admin_request_url(destination_request)
  end

  private

  def set_incoming_message
    @incoming_message = IncomingMessage.find(params[:incoming_message_id])
  end

  def set_info_request
    @info_request = @incoming_message.info_request
  end

  def check_info_request
    return if can? :admin, @info_request

    raise ActiveRecord::RecordNotFound
  end

  def check_redeliverable
    raise NotRedeliverableError unless @incoming_message.redeliverable?
  end
end
