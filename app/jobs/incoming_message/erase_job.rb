##
# Job to erase a IncomingMessage.
#
# Example:
#   IncomingMessage::EraseJob.perform_later(
#     IncomingMessage.first, editor: User.first, reason: 'GDPR request'
#   )
#
class IncomingMessage::EraseJob < ApplicationJob
  queue_as :default
  unique :until_and_while_executing, on_conflict: :log

  def perform(incoming_message, editor:, reason:)
    incoming_message.erase!(editor: editor, reason: reason)
  end
end
