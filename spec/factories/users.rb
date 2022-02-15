# == Schema Information
# Schema version: 20220210114052
#
# Table name: users
#
#  id                                :integer          not null, primary key
#  email                             :string           not null
#  name                              :string           not null
#  hashed_password                   :string           not null
#  salt                              :string
#  created_at                        :datetime         not null
#  updated_at                        :datetime         not null
#  email_confirmed                   :boolean          default(FALSE), not null
#  url_name                          :text             not null
#  last_daily_track_email            :datetime         default(Sat, 01 Jan 2000 00:00:00.000000000 GMT +00:00)
#  ban_text                          :text             default(""), not null
#  about_me                          :text             default(""), not null
#  locale                            :string
#  email_bounced_at                  :datetime
#  email_bounce_message              :text             default(""), not null
#  no_limit                          :boolean          default(FALSE), not null
#  receive_email_alerts              :boolean          default(TRUE), not null
#  can_make_batch_requests           :boolean          default(FALSE), not null
#  otp_enabled                       :boolean          default(FALSE), not null
#  otp_secret_key                    :string
#  otp_counter                       :integer          default(1)
#  confirmed_not_spam                :boolean          default(FALSE), not null
#  comments_count                    :integer          default(0), not null
#  info_requests_count               :integer          default(0), not null
#  track_things_count                :integer          default(0), not null
#  request_classifications_count     :integer          default(0), not null
#  public_body_change_requests_count :integer          default(0), not null
#  info_request_batches_count        :integer          default(0), not null
#  daily_summary_hour                :integer
#  daily_summary_minute              :integer
#  closed_at                         :datetime
#  login_token                       :string
#

FactoryBot.define do

  factory :user do
    sequence(:name) { |n| "Example User #{n}" }
    sequence(:email) { |n| "person#{n}@example.com" }
    password { 'jonespassword' }
    email_confirmed { true }
    ban_text { '' }
    confirmed_not_spam { true }

    factory :unconfirmed_user do
      email_confirmed { false }
      confirmed_not_spam { false }
    end

    factory :admin_user do
      sequence(:name) { |n| "Admin User #{n}" }
      admin
    end

    factory :pro_user do
      sequence(:name) { |n| "Pro User #{n}" }
      pro

      after(:create) do |user, evaluator|
        create(:pro_account, user: user)
      end
    end

    factory :pro_admin_user do
      name { 'Pro Admin User' }
      admin
      pro_admin
    end

    trait :admin do
      after(:create) { |user| user.add_role(:admin) }
    end

    trait :pro do
      after(:create) { |user| user.add_role(:pro) }
    end

    trait :pro_admin do
      after(:create) { |user| user.add_role(:pro_admin) }
    end

    trait :enable_otp do
      after(:build) { |object| object.enable_otp }
    end

    trait :banned do
      ban_text { 'Banned' }
    end
  end
end
