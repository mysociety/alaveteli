FactoryGirl.define do
  factory :embargo_extension do
    embargo
    extension_duration "3_months"
  end
end
