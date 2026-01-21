# Handles relevant InfoRequestEvent records on the associated InfoRequest.
module FoiAttachment::Eventable
  extend ActiveSupport::Concern

  included do
    delegate :log_event, to: :info_request
  end

  def update_and_log_event(event: {}, **params)
    return false unless update(params)

    replaced = locked? && (
               replacement_body_previously_changed? ||
               replacement_file_previously_changed?)

    log_event(
      'edit_attachment',
      event.merge(
        attachment_id: id,
        old_locked: locked_previously_was,
        locked: locked,
        replaced: replaced,
        replaced_at: replaced ? replaced_at : nil,
        replaced_filename: replaced ? filename : nil,
        replaced_reason: replaced ? replaced_reason : nil,
        old_prominence: prominence_previously_was,
        prominence: prominence,
        old_prominence_reason: prominence_reason_previously_was,
        prominence_reason: prominence_reason
      )
    )
  end

  def update_and_log_event!(event: {}, **params)
    transaction do
      update!(params)

      replaced = locked? && (
                 replacement_body_previously_changed? ||
                 replacement_file_previously_changed?)

      log_event(
        'edit_attachment',
        event.merge(
          attachment_id: id,
          old_locked: locked_previously_was,
          locked: locked,
          replaced: replaced,
          replaced_at: replaced ? replaced_at : nil,
          replaced_filename: replaced ? filename : nil,
          replaced_reason: replaced ? replaced_reason : nil,
          old_prominence: prominence_previously_was,
          prominence: prominence,
          old_prominence_reason: prominence_reason_previously_was,
          prominence_reason: prominence_reason
        )
      )
    end
  end
end
