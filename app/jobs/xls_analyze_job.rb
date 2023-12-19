class XlsAnalyzeJob < ApplicationJob
  queue_as :excel_analyzer

  attr_reader :blob

  def perform(blob)
    @blob = blob

    return unless blob.is_a?(ActiveStorage::Blob)
    return unless blob.content_type == ExcelAnalyzer::XlsAnalyzer::CONTENT_TYPE

    ActiveStorage.analyzers.prepend ExcelAnalyzer::XlsAnalyzer

    blob.analyze

    hide if blob.metadata[:excel].values.any?

  ensure
    ActiveStorage.analyzers = ActiveStorage.analyzers - [
      ExcelAnalyzer::XlsAnalyzer
    ]
  end

  def foi_attachment
    @foi_attachment ||= FoiAttachment.joins(:file_blob).
      find_by(active_storage_blobs: { id: blob })
  end

  def hide
    return unless foi_attachment
    return unless foi_attachment.is_public?

    foi_attachment.update_and_log_event(
      prominence: 'hidden',
      event: {
        editor: User.internal_admin_user,
        reason: 'ExcelAnalyzer: hidden data dectected'
      }
    )
    foi_attachment.expire
  end
end
