# Erase users in a background job. This is necessary as accounts with many
# requests can take a while to work through.
class User::ErasureJob < ApplicationJob
  # FIXME: Shouldn't have to specify a default queue.
  # Can we add this to ApplicationJob if it doesn't already use :default as the…
  # default.
  queue_as :default

  def perform(user, editor:, reason:)
    user.foi_attachments.unmasked.each(&:mask)
    user.erase!(editor: editor, reason: reason)
  end
end
