# == Schema Information
# Schema version: 20220322100510
#
# Table name: raw_emails
#
#  id         :bigint           not null, primary key
#  created_at :datetime
#  updated_at :datetime
#

FactoryBot.define do
  factory :raw_email
end
