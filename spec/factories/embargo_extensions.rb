# == Schema Information
#
# Table name: embargo_extensions
#
#  id                 :integer          not null, primary key
#  embargo_id         :integer
#  extension_duration :string(255)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#

FactoryGirl.define do
  factory :embargo_extension do
    embargo
    extension_duration "3_months"
  end
end
