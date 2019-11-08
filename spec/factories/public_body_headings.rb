# == Schema Information
# Schema version: 20220322100510
#
# Table name: public_body_headings
#
#  id            :bigint           not null, primary key
#  display_order :integer
#  created_at    :datetime
#  updated_at    :datetime
#  name          :text
#

FactoryBot.define do
  factory :public_body_heading do
    sequence(:name) { |n| "Example Public Body Heading #{n}" }
  end
end
