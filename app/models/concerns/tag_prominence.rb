require_relative 'message_prominence'

module TagProminence
  extend ActiveSupport::Concern
  include MessageProminence

  included do
    after_save :sync_prominence_attributes, :reindex_model
  end

  private

  def sync_prominence_attributes
    return unless saved_change_to_prominence? ||
                  saved_change_to_prominence_reason?

    HasTagString::HasTagStringTag.
      where.not(id: id).
      where(name: name).
      update_all(
        prominence: prominence,
        prominence_reason: prominence_reason
      )
  end

  def reindex_model
    # FIXME: we should reindex all models tagged - this will only do one model
    # because we sync to other tag instances via update_all
    return unless saved_change_to_prominence?

    case tagged_model
    when InfoRequest
      tagged_model.reindex_request_events
    else
      tagged_model.xapian_mark_needs_index
    end
  end

  module ClassMethods
    def prominence_states
      %w(normal hidden)
    end
  end
end
