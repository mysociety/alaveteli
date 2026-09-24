# == Schema Information
#
# Table name: raw_emails
#
#  id               :integer          not null, primary key
#  created_at       :datetime
#  updated_at       :datetime
#  erased_at        :datetime
#  message_id       :string
#  message_checksum :string
#

FactoryBot.define do
  factory :raw_email
end
