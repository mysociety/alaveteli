# -*- encoding : utf-8 -*-
# == Schema Information
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
#

FactoryBot.define do

  factory :public_body do
    sequence(:name) { |n| "Example Public Body #{n}" }
    sequence(:short_name) { |n| "Example Body #{n}" }
    request_email 'request@example.com'
    last_edit_editor "admin user"
    last_edit_comment "Making an edit"

    trait :defunct do
      tag_string 'defunct'
    end

    trait :not_apply do
      tag_string 'not_apply'
    end

    factory :blank_email_public_body do
      request_email ''
    end

    # DEPRECATED: Prefer traits
    factory :defunct_public_body do
      defunct
    end

    factory :not_apply_public_body do
      not_apply
    end
  end

end
