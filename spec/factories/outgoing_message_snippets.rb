FactoryBot.define do
  factory :outgoing_message_snippet, class: 'OutgoingMessage::Snippet' do
    tag_string { 'exemption:s_12' }
    name { 'The authority has applied a Section 12 exemption' }
    body { 'Test advice for a clarification' }
  end
end
