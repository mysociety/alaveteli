# frozen_string_literal: true

require 'benchmark'
require 'json'

limit = Integer(ENV.fetch('BULK_EXPORT_BENCHMARK_LIMIT', '1000'))
since = ENV['BULK_EXPORT_BENCHMARK_SINCE']
mode = ENV.fetch('BULK_EXPORT_BENCHMARK_MODE', 'active_record')

sql_count = 0
callback = lambda do |_name, _started, _finished, _id, payload|
  name = payload[:name].to_s
  sql = payload[:sql].to_s
  ignored = name == 'SCHEMA' || sql.match?(/\A(?:BEGIN|COMMIT|ROLLBACK)\b/)
  sql_count += 1 unless ignored
end

def active_record_rows(limit, since)
  scope = InfoRequest.order(:id).limit(limit)
  scope = scope.where('info_requests.updated_at >= ?', Time.zone.parse(since)) if since

  scope.find_each(batch_size: 100) do |info_request|
    yield(
      id: info_request.id,
      title: info_request.title,
      url_title: info_request.url_title,
      created_at: info_request.created_at,
      updated_at: info_request.updated_at,
      status: info_request.calculate_status,
      public_body_name: info_request.public_body&.name,
      public_body_url_name: info_request.public_body&.url_name
    )
  end
end

started_gc = GC.stat
started_objects = GC.stat[:total_allocated_objects]
rows = 0
bytes = 0

elapsed = ActiveSupport::Notifications.subscribed(
  callback, 'sql.active_record'
) do
  Benchmark.realtime do
    case mode
    when 'active_record'
      active_record_rows(limit, since) do |row|
        line = row.to_json
        rows += 1
        bytes += line.bytesize + 1
      end
    else
      raise ArgumentError, "Unknown benchmark mode: #{mode}"
    end
  end
end

finished_gc = GC.stat
result = {
  mode: mode,
  limit: limit,
  since: since,
  rows: rows,
  bytes: bytes,
  elapsed_seconds: elapsed.round(6),
  sql_count: sql_count,
  allocated_objects: finished_gc[:total_allocated_objects] - started_objects,
  gc_runs: finished_gc[:count] - started_gc[:count]
}

puts JSON.pretty_generate(result)
