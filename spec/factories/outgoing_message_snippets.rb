# == Schema Information
# Schema version: 20220210114052
#
# Table name: outgoing_message_snippets
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  name       :string
#  body       :text
#

FactoryBot.define do
  factory :outgoing_message_snippet, class: 'OutgoingMessage::Snippet' do
    tag_string { 'exemption:s_12' }
    name { 'The authority has applied a Section 12 exemption' }
    body { 'Test advice for a clarification' }
  end
end
