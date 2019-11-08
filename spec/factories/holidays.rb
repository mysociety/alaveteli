# == Schema Information
# Schema version: 20220322100510
#
# Table name: holidays
#
#  id          :bigint           not null, primary key
#  day         :date
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#

FactoryBot.define do

  factory :holiday do
    day { Date.new(2010, 1, 1) }
    description { "New Year's Day" }
  end

end
