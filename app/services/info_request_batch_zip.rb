##
# This service streams a ZIP file with all incoming/ outgoing messages and
# attachments for each request for a given info request batch
#
class InfoRequestBatchZip
  include DownloadHelper
  include Enumerable

  ZippableFile = Struct.new(:path, :body)

  attr_reader :info_request_batch

  def initialize(info_request_batch)
    @info_request_batch = info_request_batch
  end

  def files
    to_a
  end

  def name
    generate_download_filename(
      resource: 'batch',
      id: info_request_batch.id,
      title: info_request_batch.title,
      type: 'export',
      ext: 'zip'
    )
  end

  def stream(&chunks)
    block_writer = ZipTricks::BlockWrite.new(&chunks)

    ZipTricks::Streamer.open(block_writer) do |zip|
      each do |file|
        zip.write_deflated_file(file.path) { |writer| writer << file.body }
      end
    end
  end

  private

  def each(&block)
    to_enum(:each) unless block_given?

    yield prepare_dashboard_metrics

    info_request_events.each do |event|
      if event.outgoing?
        yield prepare_outgoing_message(event.outgoing_message)
      elsif event.response?
        yield prepare_incoming_message(event.incoming_message)

        event.incoming_message.foi_attachments.each do |attachment|
          yield prepare_foi_attachment(attachment)
        end
      end
    end
  end

  def info_request_events
    InfoRequestEvent.where(info_request: info_request_batch.info_requests).
      includes(:info_request, info_request: [:public_body]).
      includes(:outgoing_message).
      includes(:incoming_message, incoming_message: [:foi_attachments])
  end

  def prepare_dashboard_metrics
    metrics = InfoRequestBatchMetrics.new(info_request_batch)
    ZippableFile.new(metrics.name, metrics.to_csv)
  end

  def prepare_outgoing_message(message)
    sent_at = message.last_sent_at.to_formatted_s(:filename)
    name = "outgoing_#{message.id}.txt"
    path = [base_path(message.info_request), sent_at, name].join('/')

    ZippableFile.new(path, message.body)
  end

  def prepare_incoming_message(message)
    sent_at = message.sent_at.to_formatted_s(:filename)
    name = "incoming_#{message.id}.txt"
    path = [base_path(message.info_request), sent_at, name].join('/')

    ZippableFile.new(path, message.get_main_body_text_unfolded)
  end

  def prepare_foi_attachment(attachment)
    message = attachment.incoming_message
    sent_at = message.sent_at.to_formatted_s(:filename)

    path = [
      base_path(message.info_request),
      sent_at,
      'attachments',
      attachment.filename
    ].join('/')

    ZippableFile.new(path, attachment.body)
  end

  def base_path(info_request)
    [info_request.public_body.name, info_request.url_title].join(' - ')
  end
end
