# Detect refusal reasons in `IncomingMessage` records.
module IncomingMessage::Refusals
  extend ActiveSupport::Concern

  included do
    delegate :legislation, to: :info_request
  end

  def refusals
    legislation_references.select(&:refusal?).map(&:parent).uniq(&:to_s)
  end

  def refusals?
    refusals.any?
  end

  private

  def legislation_references
    legislation.find_references(get_main_body_text_folded)
  end
end
