##
# Job to erase a OutgoingMessage.
#
# Example:
#   OutgoingMessage::EraseJob.perform_later(
#     OutgoingMessage.first, editor: User.first, reason: 'GDPR request'
#   )
#
class OutgoingMessage::EraseJob < ApplicationJob
  queue_as :default
  unique :until_and_while_executing, on_conflict: :log

  def perform(outgoing_message, editor:, reason:)
    outgoing_message.erase(editor: editor, reason: reason)
  end
end
