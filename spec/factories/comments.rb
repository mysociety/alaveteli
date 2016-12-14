# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: comments
#
#  id              :integer          not null, primary key
#  user_id         :integer          not null
#  info_request_id :integer
#  body            :text             not null
#  visible         :boolean          default(TRUE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  locale          :text             default(""), not null
#

FactoryGirl.define do

  factory :comment do
    user
    info_request

    body 'This a wise and helpful annotation.'

    factory :visible_comment do
      visible true
    end

    factory :hidden_comment do
      visible false
    end
  end

end
