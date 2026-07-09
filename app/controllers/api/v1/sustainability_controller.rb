class Api::V1::SustainabilityController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :html_response, raise: false

  def rate_limit
    BotTrafficMetrics.increment(:rate_limit_requests)

    contract = RateLimitContract.new.call(params.permit(:ip).to_h)
    if contract.failure?
      render(
        json: { error: 'Invalid parameters', details: contract.errors.to_h },
        status: :unprocessable_entity
      )
      return
    end

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
    contract = BulkExportContract.new.call(params.permit(:limit, :since).to_h)
    if contract.failure?
      render(
        json: { error: 'Invalid parameters', details: contract.errors.to_h },
        status: :unprocessable_entity
      )
      return
    end

    # Only allow verified bots to access bulk export
    token = request.env['HTTP_X_FYI_BOT_TOKEN']
    is_verified = token.present? && token == ENV['FYI_BOT_TOKEN']

    unless is_verified
      BotTrafficMetrics.increment(:bulk_export_unauthorized)
      render(
        json: {
          error: 'Unauthorized. Bulk export requires a valid verified bot token.'
        },
        status: :unauthorized
      )
      return
    end

    BotTrafficMetrics.increment(:bulk_export_requests)

    response.headers['Content-Type'] = 'application/x-ndjson'
    response.headers['Content-Disposition'] = 'attachment; filename="requests_export.ndjson"'
    response.headers['Last-Modified'] = Time.zone.now.ctime

    self.response_body = Enumerator.new do |y|
      BulkExportStreamer.new(
        limit: contract.to_h[:limit],
        since: parsed_since(contract.to_h[:since])
      ).each do |row|
        y << "#{row.to_json}\n"
      end
    end
  end

  private

  def parsed_since(value)
    return if value.blank?

    Time.zone.parse(value)
  end
end
