# -*- encoding : utf-8 -*-
# == Schema Information
#
# Table name: users
#
#  id                      :integer          not null, primary key
#  email                   :string(255)      not null
#  name                    :string(255)      not null
#  hashed_password         :string(255)      not null
#  salt                    :string(255)      not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  email_confirmed         :boolean          default(FALSE), not null
#  url_name                :text             not null
#  last_daily_track_email  :datetime         default(2000-01-01 00:00:00 UTC)
#  admin_level             :string(255)      default("none"), not null
#  ban_text                :text             default(""), not null
#  about_me                :text             default(""), not null
#  locale                  :string(255)
#  email_bounced_at        :datetime
#  email_bounce_message    :text             default(""), not null
#  no_limit                :boolean          default(FALSE), not null
#  receive_email_alerts    :boolean          default(TRUE), not null
#  can_make_batch_requests :boolean          default(FALSE), not null
#  otp_enabled             :boolean          default(FALSE)
#  otp_secret_key          :string(255)
#  otp_counter             :integer          default(1)
#

FactoryGirl.define do

  factory :user do
    name 'Example User'
    sequence(:email) { |n| "person#{n}@example.com" }
    salt "-6116981980.392287733335677"
    hashed_password '6b7cd45a5f35fd83febc0452a799530398bfb6e8' # jonespassword
    email_confirmed true
    ban_text ""
    factory :admin_user do
      name 'Admin User'
      admin_level 'super'
    end
  end

end
