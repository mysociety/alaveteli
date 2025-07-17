# == Schema Information
# Schema version: 20250717064136
#
# Table name: user_email_histories
#
#  id         :bigint           not null, primary key
#  user_id    :bigint           not null
#  old_email  :string           not null
#  new_email  :string           not null
#  changed_at :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
FactoryBot.define do
  factory :user_email_history, class: 'User::EmailHistory' do
    association :user
    old_email { 'old@example.com' }
    new_email { 'new@example.com' }
    changed_at { Time.current }
  end
end
