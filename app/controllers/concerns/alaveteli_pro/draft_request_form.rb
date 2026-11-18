##
# Sets up the Pro request form from a draft.
#
module AlaveteliPro::DraftRequestForm
  extend ActiveSupport::Concern

  private

  def load_form_from_draft(draft)
    @draft_info_request = draft
    @info_request = InfoRequest.from_draft(draft)
    @outgoing_message = @info_request.outgoing_messages.first
    @embargo = @info_request.embargo
  end
end
