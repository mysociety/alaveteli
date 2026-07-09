class Api::V1::SustainabilityController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :html_response, raise: false

  def rate_limit
    throttle_data = request.env['rack.attack.throttle_data'] || {}
    name, data = throttle_data.find { |k, v| k.start_with?('req/') }

    if data.present?
      limit = data[:limit]
      count = data[:count]
      period = data[:period]
      epoch_time = data[:epoch_time]
      remaining = [limit - count, 0].max
      reset_in_seconds = period - (epoch_time % period)
      tier = name == 'req/verified_bot' ? 'verified_bot' : 'anonymous'
    else
      limit = 10
      remaining = 10
      reset_in_seconds = 60
      tier = 'anonymous'
    end

    render json: {
      tier: tier,
      limit: limit,
      remaining: remaining,
      reset_in_seconds: reset_in_seconds,
      advisory_status: Rack::Attack.high_system_load? ? 'degraded' : 'nominal'
    }
  end

  def bulk_export
    # Only allow verified bots to access bulk export
    token = request.env['HTTP_X_FYI_BOT_TOKEN']
    is_verified = token.present? && token == ENV['FYI_BOT_TOKEN']

    unless is_verified
      render json: { error: 'Unauthorized. Bulk export requires a valid verified bot token.' }, status: :unauthorized
      return
    end

    response.headers['Content-Type'] = 'application/x-ndjson'
    response.headers['Content-Disposition'] = 'attachment; filename="requests_export.ndjson"'
    response.headers['Last-Modified'] = Time.zone.now.ctime

    self.response_body = Enumerator.new do |y|
      InfoRequest.find_each(batch_size: 100) do |info_request|
        data = {
          id: info_request.id,
          title: info_request.title,
          url_title: info_request.url_title,
          created_at: info_request.created_at,
          updated_at: info_request.updated_at,
          status: info_request.calculate_status,
          public_body_name: info_request.public_body&.name,
          public_body_url_name: info_request.public_body&.url_name
        }
        y << data.to_json + "\n"
      end
    end
  end
end
