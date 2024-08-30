# == Schema Information
# Schema version: 20240905062817
#
# Table name: chunks
#
#  id                  :bigint           not null, primary key
#  info_request_id     :bigint
#  incoming_message_id :bigint
#  foi_attachment_id   :bigint
#  text                :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  embedding           :vector(4096)
#
FactoryBot.define do
  factory :chunk do
    text { 'Test chunk' }
    embedding { Array.new(4096) { rand } }
  end
end
