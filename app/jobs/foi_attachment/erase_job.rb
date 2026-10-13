##
# Job to erase a FoiAttachment.
#
# Example:
#   FoiAttachment::EraseJob.perform_later(
#     FoiAttachment.first, editor: User.first, reason: 'GDPR request'
#   )
#
class FoiAttachment::EraseJob < ApplicationJob
  queue_as :default
  unique :until_and_while_executing, on_conflict: :log

  def perform(attachment, editor:, reason:)
    attachment.erase(editor: editor, reason: reason)
  end
end
