# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: info_request_batches
#
#  id               :integer          not null, primary key
#  title            :text             not null
#  user_id          :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  body             :text
#  sent_at          :datetime
#  embargo_duration :string
#

FactoryGirl.define do

  factory :info_request_batch, aliases: [:batch_request]  do
    title "Example title"
    user
    body "Some text"

    factory :embargoed_batch_request do
      embargo_duration "3_months"
    end
  end
end
