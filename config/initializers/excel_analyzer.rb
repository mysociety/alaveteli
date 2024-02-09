require "excel_analyzer"

ExcelAnalyzer.on_spreadsheet_received = ->(raw_email_blob) do
  incoming_message = IncomingMessage.joins(raw_email: :file_blob).
    find_by(active_storage_blobs: { id: raw_email_blob })
  incoming_message&.parse_raw_email!
end
