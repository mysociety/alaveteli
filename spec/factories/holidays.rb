# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: holidays
#
#  id          :integer          not null, primary key
#  day         :date
#  description :text
#

FactoryGirl.define do

  factory :holiday do
    day Date.new(2010, 1, 1)
    description "New Year's Day"
  end

end
