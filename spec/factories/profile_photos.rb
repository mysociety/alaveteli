# == Schema Information
# Schema version: 20230223145243
#
# Table name: profile_photos
#
#  id         :integer          not null, primary key
#  data       :binary           not null
#  user_id    :integer
#  draft      :boolean          default(FALSE), not null
#  created_at :datetime
#  updated_at :datetime
#
FactoryBot.define do
  factory :profile_photo do
    user
    data { load_file_fixture('parrot.jpg') }
    draft { false }

    trait :draft do
      draft { true }
    end
  end
end
