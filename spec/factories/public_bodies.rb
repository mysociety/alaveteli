# == Schema Information
# Schema version: 20220210114052
#
# Table name: public_bodies
#
#  id                                     :integer          not null, primary key
#  version                                :integer          not null
#  last_edit_editor                       :string           not null
#  last_edit_comment                      :text
#  created_at                             :datetime         not null
#  updated_at                             :datetime         not null
#  home_page                              :text
#  api_key                                :string           not null
#  info_requests_count                    :integer          default(0), not null
#  disclosure_log                         :text
#  info_requests_successful_count         :integer
#  info_requests_not_held_count           :integer
#  info_requests_overdue_count            :integer
#  info_requests_visible_classified_count :integer
#  info_requests_visible_count            :integer          default(0), not null
#  name                                   :text
#  short_name                             :text
#  request_email                          :text
#  url_name                               :text
#  notes                                  :text
#  first_letter                           :string
#  publication_scheme                     :text
#  disclosure_log                         :text
#

FactoryBot.define do

  factory :public_body do
    sequence(:name) { |n| "Example Public Body #{n}" }
    sequence(:short_name) { |n| "Example Body #{n}" }
    request_email { 'request@example.com' }
    last_edit_editor { 'admin user' }
    last_edit_comment { 'Making an edit' }

    trait :defunct do
      tag_string { 'defunct' }
    end

    trait :not_apply do
      tag_string { 'not_apply' }
    end

    trait :eir_only do
      tag_string { 'eir_only' }
    end

    factory :blank_email_public_body do
      request_email { '' }
    end
  end

end
