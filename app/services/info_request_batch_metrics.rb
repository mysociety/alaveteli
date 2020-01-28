##
# This service returns basic metric information for a given info request batch.
#
class InfoRequestBatchMetrics
  include Rails.application.routes.url_helpers
  default_url_options[:host] = AlaveteliConfiguration.domain

  def initialize(info_request_batch)
    @info_request_batch = info_request_batch
  end

  def metrics
    @metrics ||= @info_request_batch.info_requests.
      includes(public_body: :translations).map do |info_request|

      url = show_alaveteli_pro_request_url(info_request.url_title)
      status = InfoRequest::State.short_description(
        info_request.calculate_status(true)
      )

      { request_url: url,
        authority_name: info_request.public_body.name,
        number_of_replies: info_request.incoming_messages.size,
        request_status: status }
    end
  end

  def name
    id = @info_request_batch.id
    url_title = MySociety::Format.simplify_url_part(
      @info_request_batch.title, 'batch', 32
    )
    timestamp = Time.zone.now.to_formatted_s(:filename)

    "batch-#{id}-#{url_title}-dashboard-#{timestamp}.csv"
  end

  def to_csv
    CSV.generate do |csv|
      csv << metrics.first.keys.map(&:to_s) if metrics.first
      metrics.each { |d| csv << d.values }
    end
  end
end
