module InfoRequest::Redactable
  extend ActiveSupport::Concern

  def make_redactions_permanent(editor:, reason: 'InfoRequest#make_redactions_permanent')
    outgoing_messages.find_each do |msg|
      msg.make_redactions_permanent(editor: editor, reason: reason)
    end

    incoming_messages.find_each do |msg|
      msg.make_redactions_permanent(editor: editor, reason: reason)
    end
  end
end
