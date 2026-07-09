# frozen_string_literal: true

class BulkExportStreamer
  DEFAULT_BATCH_SIZE = 500

  def initialize(limit: nil, since: nil, batch_size: DEFAULT_BATCH_SIZE)
    @limit = limit&.to_i
    @since = since
    @batch_size = batch_size
  end

  def each
    return enum_for(:each) unless block_given?

    if InfoRequest.custom_states_loaded?
      each_active_record_row { |row| yield row }
    else
      each_selected_row { |row| yield row }
    end
  end

  private

  attr_reader :limit, :since, :batch_size

  def each_selected_row
    remaining = limit
    last_id = 0

    loop do
      rows = fetch_rows(last_id, remaining)
      break if rows.empty?

      rows.each do |row|
        yield serialize_selected_row(row)
        remaining -= 1 if remaining
      end

      break if remaining&.zero?

      last_id = rows.last['id']
    end
  end

  def fetch_rows(last_id, remaining)
    page_limit = [remaining || batch_size, batch_size].min
    relation = InfoRequest.
      joins(:public_body).
      where('info_requests.id > ?', last_id).
      order('info_requests.id ASC').
      limit(page_limit)
    relation = relation.where('info_requests.updated_at >= ?', since) if since

    ActiveRecord::Base.connection.exec_query(
      relation.select(select_columns).to_sql
    ).to_a
  end

  def select_columns
    [
      'info_requests.id',
      'info_requests.title',
      'info_requests.url_title',
      'info_requests.created_at',
      'info_requests.updated_at',
      "#{status_expression} AS status",
      'public_bodies.name AS public_body_name',
      'public_bodies.url_name AS public_body_url_name'
    ]
  end

  def status_expression
    <<~SQL.squish
      CASE
      WHEN info_requests.awaiting_description
        THEN 'waiting_classification'
      WHEN info_requests.described_state != 'waiting_response'
        THEN info_requests.described_state
      WHEN CURRENT_DATE > info_requests.date_very_overdue_after
        THEN 'waiting_response_very_overdue'
      WHEN CURRENT_DATE > info_requests.date_response_required_by
        THEN 'waiting_response_overdue'
      ELSE 'waiting_response'
      END
    SQL
  end

  def serialize_selected_row(row)
    {
      id: row['id'],
      title: row['title'],
      url_title: row['url_title'],
      created_at: row['created_at'],
      updated_at: row['updated_at'],
      status: row['status'],
      public_body_name: row['public_body_name'],
      public_body_url_name: row['public_body_url_name']
    }
  end

  def each_active_record_row
    scope = InfoRequest.includes(:public_body).order(:id)
    scope = scope.where('info_requests.updated_at >= ?', since) if since
    scope = scope.limit(limit) if limit

    scope.find_each(batch_size: batch_size) do |info_request|
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
end
