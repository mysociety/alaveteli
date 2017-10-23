# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: public_bodies
#
#  id                                     :integer          not null, primary key
#  version                                :integer          not null
#  last_edit_editor                       :string(255)      not null
#  last_edit_comment                      :text
#  created_at                             :datetime         not null
#  updated_at                             :datetime         not null
#  home_page                              :text
#  api_key                                :string(255)      not null
#  info_requests_count                    :integer          default(0), not null
#  disclosure_log                         :text
#  info_requests_successful_count         :integer
#  info_requests_not_held_count           :integer
#  info_requests_overdue_count            :integer
#  info_requests_visible_classified_count :integer
#  info_requests_visible_count            :integer          default(0), not null
#

FactoryGirl.define do

  factory :public_body do
    sequence(:name) { |n| "Example Public Body #{n}" }
    sequence(:short_name) { |n| "Example Body #{n}" }
    request_email 'request@example.com'
    last_edit_editor "admin user"
    last_edit_comment "Making an edit"

    factory :defunct_public_body do
      after(:create) do |public_body, evaluator|
        public_body.tag_string = "defunct"
      end
    end

    factory :not_apply_public_body do
      after(:create) do |public_body, evaluator|
        public_body.tag_string = "not_apply"
      end
    end
  end


end
