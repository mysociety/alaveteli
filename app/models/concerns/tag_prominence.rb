require_relative 'message_prominence'

module TagProminence
  extend ActiveSupport::Concern
  include MessageProminence

  included do
    after_save :sync_prominence_attributes
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

  module ClassMethods
    def prominence_states
      %w(normal hidden)
    end
  end
end
