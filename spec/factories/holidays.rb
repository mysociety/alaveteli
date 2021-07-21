# == Schema Information
# Schema version: 20210114161442
#
# Table name: holidays
#
#  id          :integer          not null, primary key
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
